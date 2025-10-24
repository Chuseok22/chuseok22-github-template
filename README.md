# 🚀 GitHub 프로젝트 템플릿

[](https://www.google.com/search?q=LICENSE)

이 템플릿은 GitHub 레포지토리 설정을 제공하여, 개발에만 집중할 수 있는 환경을 만들어줍니다. **"Use this template"** 버튼 클릭 한 번으로, 체계적인 프로젝트 관리를 위한 모든 준비를 마칠 수 있습니다.

## ✨ 주요 기능

이 템플릿은 프로젝트 관리를 효율적으로 만들어 줄 다양한 기능들을 포함하고 있습니다.

| 기능 | 설명 |
| --- | --- |
| **🎯 체계적인 이슈 템플릿** | 버그, 기능 요청, 디자인 등 상황에 맞는 템플릿을 제공하여 명확한 이슈 관리를 돕습니다. |
| **💬 다양한 디스커션 템플릿** | 공지사항, 문서 등 목적에 맞는 디스커션 템플릿으로 원활한 팀 커뮤니케이션을 지원합니다. |
| **🏷️ 자동 라벨 관리** | `.github/labels/issue-label.yml` 파일만 수정하면, GitHub Actions가 **별도의 설정 없이** 자동으로 라벨을 동기화하여 일관성을 유지합니다. |
| **📝 통일된 PR 템플릿** | Pull Request 작성 양식을 통일하여, 코드 리뷰의 효율성을 높이고 변경 사항을 쉽게 파악할 수 있도록 돕습니다. |
| **🔢 자동 버전 관리(Version Management)** | `version(major minor patch): ...` 커밋 규칙으로 SemVer 자동 증가. Spring Boot/Next.js/Plain 지원. 프로젝트 파일 동기화, CHANGELOG 자동 관리, 태그(`vX.Y.Z`) 생성/푸시, **증가시에만** `repository_dispatch` 발행. **(옵션) 자동 릴리스 생성 + 릴리스 노트** |

## 🚀 시작하기

### 1. 템플릿으로 새 레포지토리 생성

1. 이 레포지토리의 오른쪽 상단에 있는 **"Use this template"** 버튼을 클릭합니다.
2. **"Create a new repository"** 를 선택합니다.
3. 새 레포지토리의 이름과 설명을 입력하고, 공개 범위를 설정합니다.
4. **"Create repository from template"** 버튼을 클릭하여 새로운 레포지토리를 생성합니다.

### 2. 라벨 자동 동기화

이제 모든 준비가 끝났습니다! 별도의 토큰 설정 없이, `.github/labels/issue-label.yml` 파일을 수정하고 커밋하기만 하면 GitHub Actions가 자동으로 레포지토리의 라벨을 동기화합니다.

```yaml
# .github/labels/issue-label.yml

- name: 새로운-라벨
  color: "0d87e0" # '#' 제외하고 6자리 색상 코드 입력
  description: "새롭게 추가된 라벨입니다."
```

이 모든 과정은 GitHub Actions 워크플로우에 미리 내장된 `GITHUB_TOKEN`을 통해 안전하게 처리되므로, 직접 Personal Access Token을 만들 필요가 없습니다.

---

## ⚙️ 자동 버전 관리(Version Management)

중앙 배포형 버전 관리 워크플로 **(chuseok22/version-management)** 가 템플릿에 포함됩니다. 기본 브랜치에 규칙에 맞는 커밋이 들어오면 **버전 증가 → 파일 동기화 → CHANGELOG 갱신 → Git Tag 생성/푸시 → (옵션) GitHub Release 생성(자동 노트)** 가 자동으로 이뤄집니다.

### ✅ 커밋 규칙 (필수)

커밋 **제목(subject)** 으로 SemVer 증가를 판정합니다.

```
version(major): drop legacy API
version(minor): add CSV export
version(patch): fix null check
```

> 머지 전략에 따라 동작이 달라질 수 있습니다. **스쿼시 머지 + PR 제목에 규칙 적용** 또는 **메인에서 빈 커밋으로 버전 커밋**(예: `git commit --allow-empty -m "version(patch): ..."` ) 등 팀 정책을 결정해 주세요.

### 🧭 빠른 시작

템플릿에는 아래 워크플로가 포함돼 있습니다. (소비자 레포에서 **그대로 사용** 가능)

`/.github/workflows/chuseok22-version-management.yml`

```yaml
name: Version Management (from chuseok22/version-management)

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: write
  actions: read

jobs:
  chuseok22-version-bump:
    uses: chuseok22/version-management/.github/workflows/auto-version.yml@v1
    with:
      project_type: "auto"                 # spring | next | plain | auto
      default_branch: "main"
      tag_prefix: "v"
      default_version: "0.0.0"
      next_constants_path: "src/constants/version.ts"  # Next.js만 대상
      sync_app_yaml: "false"               # Spring application.yml version 치환
      workdir: ""                          # 모노레포면 "backend"/"web" 등 하위 경로
      dispatch_on_bump: "true"             # 버전 증가시에만 후속 트리거
      dispatch_event_type: "version-bumped"
      plain_version_file: "VERSION"        # Plain 프로젝트일 때 버전 파일 경로

      # (옵션) 릴리스 생성 제어
      create_release: "true"               # 버전 증가 시 릴리스 생성
      release_latest: "true"               # 최신 릴리스로 표시
      release_prerelease: "false"          # 프리릴리스로 표시(예: M1, RC)
```

> **프로젝트 타입 자동 탐지**  
> `package.json` → **next**, `build.gradle` → **spring**, 그 외 → **plain**

### 📄 Plain(일반) 프로젝트 동작

- 버전 파일(`VERSION`)이 **없으면 생성** → `X.Y.Z` **한 줄** 작성
- 버전 파일이 **있으면 완전 덮어쓰기** → 항상 최신 버전 **한 줄만** 유지

### 🔧 권장 권한/러너

- Runner: `ubuntu-latest`, Node: `20`
- `permissions: contents: write`
- `actions/checkout@v4`에서 `fetch-depth: 0` 권장(태그/이력 필요)

---

## 📁 디렉토리 구조

```
.github/
├── DISCUSSION_TEMPLATE/
│   ├── announcements.yaml      # 📢 공지사항 디스커션 템플릿
│   └── documents.yaml          # 📄 문서 디스커션 템플릿
├── ISSUE_TEMPLATE/
│   ├── bug_report.md           # ❗ 버그 리포트 템플릿
│   ├── config.yml              # ⚙️ 이슈 템플릿 선택 화면 설정
│   ├── design_request.md       # 🎨 디자인 요청 템플릿
│   └── feature_request.md      # 🚀 기능 요청 템플릿
├── labels/
│   └── issue-label.yml         # 🏷️ 라벨 정의 파일
├── workflows/
│   ├── sync-issue-labels.yaml  # 🔄 라벨 자동 동기화 워크플로우
│   └── chuseok22-version-management.yml  # 🔢 자동 버전 관리 워크플로(재사용 호출)
└── PULL_REQUEST_TEMPLATE.md    # 📝 PR 템플릿
```

---

## 🎨 기본 라벨 목록

### 이슈/상태 관리(한국어)

| 라벨명 | 색상 | 설명 |
| --- | --- | --- |
| 긴급 | `#ff0000` | 긴급한 작업 |
| 문서 | `#000000` | 문서 작업 관련 |
| 버그 | `#5715EE` | 버그 수정이 필요한 작업 |
| 보류 | `#D00ACE` | 추후 작업 진행 예정 |
| 작업 완료 | `#0000ff` | 작업 완료 상태인 경우 (이슈 폐쇄) |
| 작업 전 | `#E6D4AE` | 작업 시작 전 준비 상태 |
| 작업 중 | `#a2eeef` | 작업이 진행 중인 상태 |
| 취소 | `#f28b25` | 작업 취소됨 |
| 담당자 확인 중 | `#ffd700` | 담당자 확인 중 (담당자 확인 후 '작업완료' or '피드백') |
| 피드백 | `#228b22` | 담당자 확인 후 수정 필요 |

### PR 분류(릴리스 노트용, 영어)

> 자동 생성 릴리스 노트 분류는 **PR 라벨** 기준입니다. 아래 라벨을 PR에 붙이면 릴리스 노트 섹션으로 분류하기 쉽습니다.

| 라벨명 | 색상 | 설명 |
| --- | --- | --- |
| feat | `#14b8a6` | 새로운 기능 추가 (Feature) |
| enhancement | `#22c55e` | 기능 개선/향상 (Enhancement) |
| fix | `#f43f5e` | 버그 수정 (Fix) |
| hotfix | `#0ea5e9` | 긴급 핫픽스 (Hotfix) |
| chore | `#64748b` | 유지보수/빌드/잡무 (Chore) |
| refactor | `#d946ef` | 리팩터링 (Refactor) |
| ci | `#0369a1` | CI/CD 파이프라인/워크플로 변경 (CI) |
| skip-release | `#94a3b8` | 자동 릴리스 노트에서 제외 |

---

## 🔍 문제 해결 (Troubleshooting)

**라벨 동기화가 작동하지 않나요?**  
1) **GitHub Actions 활성화 확인**: Settings → Actions → General 에서 `Allow all actions and reusable workflows` 권장.  
2) **실행 로그 확인**: **Actions** 탭에서 “Sync GitHub Labels” 워크플로 실행 로그 점검.  
3) **파일 경로 확인**: 워크플로 내 `yaml-file` 경로가 `.github/labels/issue-label.yml` 인지 확인.

**Version Management가 동작하지 않나요?**  
1) **커밋 제목 패턴** 확인: `version(major|min|patch): ...` 형식인지.  
2) **브랜치** 확인: `main`(또는 `default_branch`)에서만 bump.  
3) **체크아웃 깊이**: `actions/checkout@v4`에 `fetch-depth: 0`.  
4) **권한**: `permissions: contents: write`.  
5) **프로젝트 타입 탐지**: `package.json`/`build.gradle` 유무에 따라 `next`/`spring` 판정, 그 외는 `plain`.  
6) **Plain 버전 파일 경로**: 기본 `VERSION`, 커스텀 시 `plain_version_file` 입력 사용.  
7) **머지 전략**: 스쿼시 머지 + PR 제목 규칙 적용 또는 메인에서 빈 커밋으로 버전 커밋 처리.

---

## 💡 기여하기 (Contributing)

이 템플릿을 더 멋지게 만들고 싶으신가요? 개선 아이디어가 있다면 언제든지 Pull Request를 보내주세요! 여러분의 기여를 환영합니다.

1. 이 레포지토리를 Fork 합니다.  
2. `feature/기능`과 같이 새로운 브랜치를 생성합니다.  
3. 변경 사항을 커밋합니다.  
4. 생성한 브랜치로 Push 합니다.  
5. Pull Request를 생성하여 변경 내용에 대해 설명해주세요.

---

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.
