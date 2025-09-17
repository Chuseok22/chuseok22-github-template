# 🚀 GitHub 프로젝트 템플릿

[](https://www.google.com/search?q=LICENSE)

매번 새로운 프로젝트를 시작할 때마다 GitHub 설정을 처음부터 다시 하고 계신가요? 반복되는 이슈 템플릿, 라벨, 워크플로우 설정에 지치셨다면, 이 템플릿이 완벽한 해결책이 될 것입니다\!

이 템플릿은 GitHub 레포지토리 설정을 제공하여, 개발에만 집중할 수 있는 환경을 만들어줍니다. **"Use this template"** 버튼 클릭 한 번으로, 체계적인 프로젝트 관리를 위한 모든 준비를 마칠 수 있습니다.

## ✨ 주요 기능

이 템플릿은 프로젝트 관리를 효율적으로 만들어 줄 다양한 기능들을 포함하고 있습니다.

| 기능 | 설명 |
| --- | --- |
| **🎯 체계적인 이슈 템플릿** | 버그, 기능 요청, 디자인 등 상황에 맞는 템플릿을 제공하여 명확한 이슈 관리를 돕습니다. |
| **💬 다양한 디스커션 템플릿** | 공지사항, 문서 등 목적에 맞는 디스커션 템플릿으로 원활한 팀 커뮤니케이션을 지원합니다. |
| **🏷️ 자동 라벨 관리** | `.github/labels/issue-label.yml` 파일만 수정하면, GitHub Actions가 **별도의 설정 없이** 자동으로 라벨을 동기화하여 일관성을 유지합니다. |
| **📝 통일된 PR 템플릿** | Pull Request 작성 양식을 통일하여, 코드 리뷰의 효율성을 높이고 변경 사항을 쉽게 파악할 수 있도록 돕습니다. |

## 🚀 시작하기

### 1\. 템플릿으로 새 레포지토리 생성

1.  이 레포지토리의 오른쪽 상단에 있는 **"Use this template"** 버튼을 클릭합니다.
2.  **"Create a new repository"** 를 선택합니다.
3.  새 레포지토리의 이름과 설명을 입력하고, 공개 범위를 설정합니다.
4.  **"Create repository from template"** 버튼을 클릭하여 새로운 레포지토리를 생성합니다.

### 2\. 라벨 자동 동기화

이제 모든 준비가 끝났습니다\! 별도의 토큰 설정 없이, `.github/labels/issue-label.yml` 파일을 수정하고 커밋하기만 하면 GitHub Actions가 자동으로 레포지토리의 라벨을 동기화합니다.

```yaml
# .github/labels/issue-label.yml

- name: 새로운-라벨
  color: "0d87e0" # '#' 제외하고 6자리 색상 코드 입력
  description: "새롭게 추가된 라벨입니다."
```

이 모든 과정은 GitHub Actions 워크플로우에 미리 내장된 `GITHUB_TOKEN`을 통해 안전하게 처리되므로, 직접 Personal Access Token을 만들 필요가 없습니다.

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
│   └── sync-issue-labels.yaml  # 🔄 라벨 자동 동기화 워크플로우
└── PULL_REQUEST_TEMPLATE.md    # 📝 PR 템플릿
```

## 🎨 기본 라벨 목록

| 라벨명 | 색상 | 설명 |
| --- | --- | --- |
| 긴급 |  `#ff0000` | 긴급한 작업 |
| 문서 |  `#000000` | 문서 작업 관련 |
| 버그 |  `#5715EE` | 버그 수정이 필요한 작업 |
| 보류 |  `#D00ACE` | 추후 작업 진행 예정 |
| 작업 완료 |  `#0000ff` | 작업 완료 상태인 경우 (이슈 폐쇄) |
| 작업 전 |  `#E6D4AE` | 작업 시작 전 준비 상태 |
| 작업 중 |  `#a2eeef` | 작업이 진행 중인 상태 |
| 취소 |  `#f28b25` | 작업 취소됨 |
| 담당자 확인 중 |  `#ffd700` | 담당자 확인 중 (담당자 확인 후 '작업완료' or '피드백') |
| 피드백 |  `#228b22` | 담당자 확인 후 수정 필요 |

## 🔍 문제 해결 (Troubleshooting)

**라벨 동기화가 작동하지 않나요?**

1.  **GitHub Actions 활성화 확인**:
    * 레포지토리의 **Settings → Actions → General** 메뉴에서 Actions가 활성화되어 있는지 확인하세요. (`Allow all actions and reusable workflows` 선택 권장)
2.  **GitHub Actions 로그 확인**:
    * 레포지토리의 **Actions** 탭에서 "Sync GitHub Labels" 워크플로우의 실행 로그를 확인하여 에러 메시지가 있는지 살펴보세요.
3.  **파일 경로 확인**:
    * `.github/workflows/sync-issue-labels.yaml` 파일 내의 `yaml-file` 경로가 `.github/labels/issue-label.yml`로 올바르게 설정되어 있는지 확인하세요.


## 💡 기여하기 (Contributing)

이 템플릿을 더 멋지게 만들고 싶으신가요? 개선 아이디어가 있다면 언제든지 Pull Request를 보내주세요\! 여러분의 기여를 환영합니다.

1.  이 레포지토리를 Fork 합니다.
2.  `feature/기능`과 같이 새로운 브랜치를 생성합니다.
3.  변경 사항을 커밋합니다.
4.  생성한 브랜치로 Push 합니다.
5.  Pull Request를 생성하여 변경 내용에 대해 설명해주세요.

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.