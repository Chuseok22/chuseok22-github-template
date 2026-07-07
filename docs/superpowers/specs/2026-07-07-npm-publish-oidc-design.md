# npm-publish.yml OIDC Trusted Publishing 전환 설계

## 배경 / 문제

`.github/workflows/npm-publish.yml`은 `secrets.NPM_TOKEN`(npmjs.com 발급 PAT)을 `NODE_AUTH_TOKEN`으로 주입해 `npm publish`를 수행한다. 이 워크플로우는 `github-template` 저장소를 통해 여러 실제 프로젝트 저장소에 복제되어 쓰이는데, 다음 문제가 확인되었다.

- npm이 2025-11-05부로 보안 정책을 변경해 **classic(만료 없는) 토큰 신규 발급을 완전히 중단**했고, 기존 classic 토큰도 2025-11-19부로 전부 만료 처리했다.
- write 권한이 있는 granular 토큰은 **최대 90일**로 만료가 강제되며, 조직/엔터프라이즈 관리자도 이 상한을 늘릴 수 없다.
- 즉 "토큰을 길게 발급받아 회피"하는 방법은 npm 정책상 원천적으로 막혀 있고, 이 워크플로우를 쓰는 모든 저장소에서 90일마다 토큰을 재발급하고 GitHub secret을 갱신해야 하는 구조적 문제가 있다.
- npm은 공식적으로 이 문제의 대안으로 **GitHub Actions OIDC 기반 Trusted Publishing**(2025-07-31 GA)을 제시하고 있다.

참고 자료:
- https://docs.npmjs.com/trusted-publishers/
- https://github.blog/changelog/2025-07-31-npm-trusted-publishing-with-oidc-is-generally-available/
- https://github.blog/changelog/2025-11-05-npm-security-update-classic-token-creation-disabled-and-granular-token-changes/
- https://philna.sh/blog/2026/01/28/trusted-publishing-npm/
- https://github.com/npm/cli/issues/8544 (최초 배포에 OIDC를 쓸 수 없는 제약에 대한 미해결 이슈)

## 목표

- `npm-publish.yml` 템플릿을 OIDC Trusted Publishing 기반으로 전환해, **이 템플릿으로 새로 생성되는 저장소**부터는 토큰 만료로 인한 배포 실패/수동 갱신 부담을 구조적으로 제거한다.
- 최초 배포(부트스트랩) 이후에는 `NPM_TOKEN`이 만료되거나 삭제되어도 배포 파이프라인이 끊기지 않도록 한다.

## 비목표 (Non-goals)

- 이미 `NPM_TOKEN`으로 운영 중인 기존 저장소의 마이그레이션은 이번 설계 범위에 포함하지 않는다. (템플릿만 수정, 필요 시 각 저장소에서 개별적으로 동일한 절차를 따라 추후 전환 가능)
- GitHub Environment 승인 게이트(수동 배포 승인) 도입은 이번 범위에 포함하지 않는다. 현재의 완전 자동 배포 흐름(`main` push → 버전 자동 증가 → `repository_dispatch` → 배포)을 유지한다.

## 설계

### 1. `npm-publish.yml` 변경 사항 (추가형, 기존 라인 제거 없음)

| 항목 | 현재 | 변경 후 |
|---|---|---|
| `permissions` | `contents: write`, `actions: read` | `id-token: write` **추가** (기존 항목 유지) |
| Node 버전 (`setup-node`) | `20` | `22` (OIDC 요구사항: Node 22.14.0+) |
| npm CLI 버전 | setup-node 기본 번들 버전 | `setup-node` 직후 `npm install -g npm@latest` 스텝 추가 (OIDC 요구사항: npm CLI 11.5.1+) |
| 배포 스텝 env (`NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}`) | 있음 | **그대로 유지** (제거하지 않음) |
| `npm publish` 커맨드 | `npm publish --access public` | `npm publish --access public --provenance` (`--provenance` 명시 추가) |

`NODE_AUTH_TOKEN`을 제거하지 않는 이유: npm CLI는 인증 시 **OIDC를 먼저 시도하고, 실패 시 토큰으로 폴백**하는 순서로 동작한다. 따라서:

- 패키지에 아직 Trusted Publisher가 등록되지 않은 최초 배포 시점에는 OIDC가 성립하지 않아 자동으로 토큰 인증으로 폴백된다 → 최초 배포 성공.
- 최초 배포 후 npmjs.com에서 Trusted Publisher를 등록하면, 이후로는 OIDC 인증이 먼저 성공하므로 토큰은 더 이상 사용되지 않는다.
- 그 결과 토큰이 90일 뒤 만료되거나 GitHub secret에서 삭제되어도 배포는 계속 정상 동작한다. 워크플로우 파일을 "최초용"과 "이후용"으로 분기할 필요가 없다.

체크아웃, 트리거(`repository_dispatch`/`workflow_dispatch`), `npm ci`, `npm run build` 스텝은 변경하지 않는다.

### 2. 저장소별 최초 설정 절차 (1회성, 워크플로우 실행과 별개로 사람이 수행)

이 템플릿으로 새 저장소를 만들 때마다 아래 순서를 따른다.

1. **최초 배포는 CI로 진행** — GitHub secret에 90일 만료 granular 토큰(`NPM_TOKEN`, publish 권한)을 등록하고, `workflow_dispatch` 또는 버전 범프를 통해 `npm-publish.yml`을 실행해 최초 버전(예: `v0.0.1`)을 배포한다.
2. **npmjs.com에서 Trusted Publisher 등록** — `npmjs.com/package/<패키지명>/access` 경로에서 GitHub Actions publisher 추가:
   - Organization/User, Repository 이름, Workflow 파일명(`npm-publish.yml`, 정확히 일치해야 함) 입력
   - Environment는 비워둠 (승인 게이트 미사용, 비목표 참고)
   - Allowed actions: `npm publish` 체크
3. **`package.json`의 `repository.url` 확인** — Trusted Publisher에 등록한 저장소 경로와 정확히 일치해야 인증이 통과된다. 불일치 시 OIDC 인증이 실패하고 토큰 폴백에만 의존하게 된다.
4. 이후 `main` push → 버전 자동 증가(`chuseok22-version-management.yml`) → `version-bumped` dispatch → `npm-publish.yml`이 OIDC로 인증 후 배포. 토큰 등록/갱신이 더 이상 필요 없다.

### 3. 문서화

이 저장소는 워크플로우별 시크릿/설정 가이드를 루트에 `<워크플로우명> Workflow Setup.md` 형태의 독립 문서로 관리하는 기존 컨벤션이 있다(예: `Capacitor App Workflow Setup.md`). 구현 단계에서 동일한 컨벤션으로 `NPM Publish Workflow Setup.md` 문서를 추가해 위 2번 절차(최초 설정 체크리스트)를 안내하는 것을 권장한다. (본 설계 문서 자체는 `docs/superpowers/specs/`에 별도 보관)

## 에러 처리 / 엣지 케이스

- **Trusted Publisher 미등록 상태에서 토큰까지 만료된 경우**: 배포가 실패한다. 이 경우 새 90일 토큰을 재발급해 1회 배포 후, Trusted Publisher 등록 절차(2번)를 반드시 수행해야 재발이 방지된다.
- **`repository.url` 불일치**: OIDC 인증이 조용히 실패하고 토큰 폴백에만 의존하는 상태가 될 수 있다. 최초 설정 시 반드시 확인.
- **패키지당 Trusted Publisher는 1개만 등록 가능**: 여러 워크플로우 파일에서 배포를 시도하는 구조라면 충돌 가능. 현재는 `npm-publish.yml` 단일 파일만 배포를 수행하므로 해당 없음.

## 테스트 / 검증 계획

- 워크플로우 문법 검증: `actionlint` 또는 GitHub UI의 워크플로우 유효성 검사로 YAML 구문 확인.
- 신규 테스트 저장소(또는 draft 패키지)를 이 템플릿으로 생성해 위 2번 절차를 실제로 수행:
  1. `NPM_TOKEN` 등록 후 최초 배포 성공 확인
  2. Trusted Publisher 등록
  3. `NPM_TOKEN` secret을 의도적으로 삭제/무효화한 뒤 버전 범프 → 배포가 OIDC만으로 성공하는지 확인
- 위 실제 검증은 npm 레지스트리에 실제 패키지를 생성하는 부수효과가 있으므로, 실행 여부와 시점은 구현 단계에서 사용자와 별도 확인 후 진행한다.

## 롤아웃

- 이번 변경은 템플릿 파일(`npm-publish.yml`)에만 적용하며, 기존에 이 워크플로우로 운영 중인 저장소에는 영향 없음(각 저장소가 템플릿을 다시 가져오기 전까지는 그대로 기존 `NPM_TOKEN` 방식으로 동작).
