# npm 배포 워크플로우 설정 가이드 (OIDC Trusted Publishing)

이 문서는 `npm-publish.yml` 워크플로우를 사용하는 저장소에서 **최초 1회만 수행하면 되는 설정 절차**를 정리한다. 이 절차를 마치면 이후 `NPM_TOKEN`이 만료되거나 삭제되어도 배포가 계속 정상 동작한다.

## 왜 이 절차가 필요한가

npm은 2025-11부로 만료 없는 classic 토큰의 신규 발급을 중단했고, write 권한이 있는 granular 토큰은 최대 90일 만료가 강제된다. 토큰을 아무리 길게 발급받아도 90일마다 갱신해야 하므로, 이 워크플로우는 **최초 배포에만 토큰을 쓰고 이후에는 OIDC(Trusted Publishing)로 전환**하는 방식으로 설계되어 있다.

## 0. 필요한 Secret

| Secret 이름 | 의미 | 형식 | 비고 |
|---|---|---|---|
| `NPM_TOKEN` | npmjs.com에서 발급한 granular 토큰 (publish 권한) | 문자열 | **최초 배포 1회에만 필요**. 만료 최대 90일. Trusted Publisher 등록 후에는 이 토큰이 만료/삭제되어도 배포에 영향 없음. |

## 1. npm 토큰 발급 및 GitHub Secret 등록

1. npmjs.com 로그인 → 프로필 → **Access Tokens** → **Generate New Token** → **Granular Access Token**
2. Permissions: **Read and write**, 대상 패키지(또는 전체) 선택, 만료 기간은 최대 90일로 설정
3. GitHub Repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
4. Name: `NPM_TOKEN`, Value: 위에서 발급한 토큰 값

## 2. 최초 배포 실행

- `workflow_dispatch`로 `npm-publish.yml`을 수동 실행하거나, 버전 범프를 트리거해 최초 버전(예: `v0.0.1`)을 배포한다.
- 이 시점에는 npmjs.com에 아직 Trusted Publisher가 없으므로, npm CLI가 OIDC 시도 후 자동으로 `NPM_TOKEN` 인증으로 폴백해 배포된다.
- 참고: `workflow_dispatch`의 `tag` input은 현재 체크아웃 스텝에서 실제로 사용되지 않으며, 항상 `main` 브랜치 기준으로 배포된다. 수동 실행 전 `main`에 원하는 초기 버전이 반영돼 있는지 확인한다.

## 3. npmjs.com에서 Trusted Publisher 등록

1. 최초 배포가 완료되어 패키지가 npm 레지스트리에 존재하는 것을 확인한다.
2. `https://www.npmjs.com/package/<패키지명>/access` 접속
3. **Trusted Publisher** 섹션에서 GitHub Actions 추가:
   - Organization or user: GitHub organization/username
   - Repository: 저장소 이름
   - Workflow filename: `npm-publish.yml` (정확히 일치해야 함)
   - Environment: 비워둠
   - Allowed actions: `npm publish` 체크
4. 저장

## 4. `package.json`의 `repository.url` 확인

Trusted Publisher에 등록한 저장소 경로와 `package.json`의 `repository.url`이 정확히 일치하는지 확인한다. 불일치 시 OIDC 인증이 실패하고 `NPM_TOKEN` 폴백에만 계속 의존하게 된다.

```json
{
  "repository": {
    "type": "git",
    "url": "git+https://github.com/<organization>/<repository>.git"
  }
}
```

## 5. 이후 동작

- `main` push → 버전 자동 증가(`chuseok22-version-management.yml`) → `version-bumped` dispatch → `npm-publish.yml` 실행 → npm CLI가 OIDC로 먼저 인증 시도 → 성공 시 `NPM_TOKEN`은 사용되지 않음.
- `NPM_TOKEN`이 90일 후 만료되어도, Trusted Publisher가 정상 등록되어 있다면 배포는 계속 성공한다. 토큰을 갱신하거나 GitHub secret에서 삭제해도 무방하다.

## 참고: Provenance

이 워크플로우는 `--provenance` 플래그를 강제하지 않는다. 소스 저장소가 **public**이고 Trusted Publishing으로 배포되면 npm이 자동으로 provenance를 첨부한다. 저장소가 **private**이면 provenance는 생성되지 않는다(npm 정책상 private 소스 저장소는 provenance를 지원하지 않음) — 이는 정상 동작이며 배포 자체에는 영향이 없다.
