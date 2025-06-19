# 🚀 Spring Boot 프로젝트 GitHub 템플릿

Spring Boot 프로젝트를 위한 GitHub 템플릿 레포지토리입니다. 이 템플릿을 사용하면 매번 새로운 프로젝트를 시작할 때마다 GitHub 설정(Issue 템플릿, Discussion 템플릿, 라벨 등)을 반복적으로 작성할 필요가 없습니다.

## 📋 포함된 기능

### 🎯 Issue 템플릿
- **버그 이슈**: 버그 보고를 위한 상세한 템플릿
- **기능 요청**: 새로운 기능 제안을 위한 템플릿  
- **디자인 요청**: UI/UX 관련 요청 템플릿
- **자동 이슈 라벨**: Issue 작성 시 자동으로 적절한 라벨 적용

### 💬 Discussion 템플릿
- **공지사항**: 프로젝트 공지사항 작성용
- **문서**: 프로젝트 문서 관련 토론용

### 🏷️ 자동 라벨 관리
- **자동 라벨 동기화**: `issue-label.yml` 파일 변경 시 자동으로 GitHub 라벨 업데이트
- **미리 정의된 라벨**: 긴급, 버그, 작업 상태 등 프로젝트 관리에 필요한 라벨들

### 📝 Pull Request 템플릿
- PR 작성 시 일관된 형식 제공

## 🔧 사용 방법

### 1. 템플릿으로 새 레포지토리 생성

1. 이 레포지토리의 **"Use this template"** 버튼을 클릭합니다.
2. **"Create a new repository"**를 선택합니다.
3. 새 레포지토리 이름과 설정을 입력합니다.
4. **"Create repository from template"**를 클릭합니다.

### 2. GitHub Personal Access Token 설정 (중요!)

라벨 자동 동기화 기능을 사용하려면 GitHub Personal Access Token을 설정해야 합니다.

#### 2.1 Personal Access Token 생성

1. GitHub 우상단의 프로필 이미지를 클릭하고 **Settings**를 선택합니다.
2. 왼쪽 사이드바에서 **Developer settings**를 클릭합니다.
3. **Personal access tokens** → **Tokens (classic)**을 선택합니다.
4. **Generate new token** → **Generate new token (classic)**을 클릭합니다.
5. 토큰 설정:
   - **Note**: `Repository Label Sync` (토큰 설명)
   - **Expiration**: 원하는 만료 기간 선택
   - **Scopes**: 다음 권한들을 체크하세요:
     - `repo` (Full control of private repositories)
     - `public_repo` (Access public repositories)
6. **Generate token**을 클릭합니다.
7. **생성된 토큰을 복사하여 안전한 곳에 저장하세요** (페이지를 벗어나면 다시 볼 수 없습니다)

#### 2.2 레포지토리에 Secret 추가

1. 새로 생성한 레포지토리로 이동합니다.
2. **Settings** 탭을 클릭합니다.
3. 왼쪽 사이드바에서 **Secrets and variables** → **Actions**를 선택합니다.
4. **New repository secret**을 클릭합니다.
5. Secret 설정:
   - **Name**: `GH_TOKEN`
   - **Secret**: 앞서 생성한 Personal Access Token을 붙여넣기
6. **Add secret**을 클릭합니다.

### 3. 라벨 자동 동기화 활성화

라벨 설정을 변경하려면:

1. `.github/ISSUE_TEMPLATE/issue-label.yml` 파일을 편집합니다.
2. 원하는 라벨을 추가/수정/삭제합니다:

```yaml
- name: 라벨명
  color: 16진수색상코드 (예: ff0000)
  description: 라벨 설명
```

3. 파일을 커밋하고 푸시하면 GitHub Actions가 자동으로 실행되어 라벨을 동기화합니다.

## 📁 디렉토리 구조

```
.github/
├── DISCUSSION_TEMPLATE/
│   ├── announcements.yaml      # 공지사항 토론 템플릿
│   └── documents.yaml          # 문서 토론 템플릿
├── ISSUE_TEMPLATE/
│   ├── bug_report.md           # 버그 리포트 템플릿
│   ├── config.yml              # Issue 템플릿 설정
│   ├── design_request.md       # 디자인 요청 템플릿
│   ├── feature_request.md      # 기능 요청 템플릿
│   └── issue-label.yml         # 라벨 정의 파일
├── workflows/
│   └── sync-issue-labels.yaml  # 라벨 자동 동기화 워크플로
├── OLD_ISSUE_TEMPLATE.md       # 기본 Issue 템플릿 (참고용)
└── PULL_REQUEST_TEMPLATE.md    # PR 템플릿
```

## 🎨 라벨 커스터마이징

기본 제공되는 라벨:

| 라벨명 | 색상 | 설명 |
|--------|------|------|
| 긴급 | ![#ff0000](https://via.placeholder.com/15/ff0000/000000?text=+) `#ff0000` | 긴급한 작업 |
| 문서 | ![#000000](https://via.placeholder.com/15/000000/000000?text=+) `#000000` | 문서 작업 관련 |
| 버그 | ![#5715EE](https://via.placeholder.com/15/5715EE/000000?text=+) `#5715EE` | 버그 수정이 필요한 작업 |
| 보류 | ![#D00ACE](https://via.placeholder.com/15/D00ACE/000000?text=+) `#D00ACE` | 추후 작업 진행 예정 |
| 작업 완료 | ![#0000ff](https://via.placeholder.com/15/0000ff/000000?text=+) `#0000ff` | 작업 완료 상태 |
| 작업 전 | ![#E6D4AE](https://via.placeholder.com/15/E6D4AE/000000?text=+) `#E6D4AE` | 작업 시작 전 준비 상태 |
| 작업 중 | ![#a2eeef](https://via.placeholder.com/15/a2eeef/000000?text=+) `#a2eeef` | 작업이 진행 중인 상태 |
| 취소 | ![#f28b25](https://via.placeholder.com/15/f28b25/000000?text=+) `#f28b25` | 작업 취소됨 |
| 담당자 확인 중 | ![#ffd700](https://via.placeholder.com/15/ffd700/000000?text=+) `#ffd700` | 담당자 확인 중 |
| 피드백 | ![#228b22](https://via.placeholder.com/15/228b22/000000?text=+) `#228b22` | 담당자 확인 후 수정 필요 |

## 🔍 문제 해결

### 라벨 동기화가 작동하지 않는 경우

1. **REPOSITORY_TOKEN Secret 확인**:
   - Repository Settings → Secrets and variables → Actions에서 `GH_TOKEN`이 정확히 설정되어 있는지 확인
   - Token이 만료되지 않았는지 확인

2. **Token 권한 확인**:
   - Personal Access Token에 `repo` 또는 `public_repo` 권한이 있는지 확인

3. **GitHub Actions 로그 확인**:
   - Actions 탭에서 "Sync GitHub Labels" 워크플로의 실행 로그를 확인
   - 에러 메시지가 있다면 해당 내용을 바탕으로 문제 해결

4. **파일 경로 확인**:
   - `sync-issue-labels.yaml` 파일에서 `yaml-file` 경로가 올바른지 확인 (현재: `.github/ISSUE_TEMPLATE/issue-label.yml`)

### 일반적인 문제들

- **Issue 템플릿이 보이지 않음**: 브라우저 캐시를 클리어하고 다시 시도
- **라벨 색상이 적용되지 않음**: 색상 코드가 올바른 16진수 형식인지 확인 (예: `ff0000`)
- **워크플로가 실행되지 않음**: `.github/ISSUE_TEMPLATE/issue-label.yml` 파일을 수정했는지 확인

## 🚀 추가 커스터마이징

### Spring Boot 프로젝트에 맞는 추가 설정

이 템플릿을 사용한 후, Spring Boot 프로젝트에 맞게 추가로 설정할 수 있는 것들:

1. **CI/CD 워크플로**: 
   - GitHub Actions를 사용한 자동 빌드 및 테스트
   - Docker 이미지 빌드 및 배포

2. **코드 품질 관리**:
   - SonarQube 연동
   - 코드 커버리지 측정

3. **보안 스캔**:
   - 의존성 취약점 검사
   - 코드 보안 스캔

## 💡 기여하기

이 템플릿에 개선사항이 있다면 언제든지 PR을 보내주세요!

1. 이 레포지토리를 Fork합니다.
2. 새로운 브랜치를 생성합니다. (`git checkout -b feature/amazing-feature`)
3. 변경사항을 커밋합니다. (`git commit -m 'Add some amazing feature'`)
4. 브랜치에 Push합니다. (`git push origin feature/amazing-feature`)
5. Pull Request를 생성합니다.

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

**참고**: 이 템플릿은 Spring Boot 프로젝트를 위해 최적화되어 있으며, 다른 프로젝트 타입에서도 사용할 수 있습니다.