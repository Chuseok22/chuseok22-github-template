# 🚀 GitHub 자동화 템플릿

<!-- 수정하지마세요 자동으로 동기화 됩니다 -->
## 최신 버전 : v1.0.4 (2025-08-20)

[전체 버전 기록 보기](CHANGELOG.md)

_참고: `CHANGELOG.md`는 자동 생성됩니다. 수동으로 수정하지 마세요. 변경 소스는 `CHANGELOG.json`입니다._

개요
---

다양한 프로젝트 타입에서 **버전 관리**, **체인지로그 생성**, **빌드 테스트**, **배포**를 자동화하는 GitHub Actions 워크플로우 템플릿입니다.

## 🌟 주요 기능

이 템플릿 프로젝트는 개발 생산성과 일관성을 대폭 향상시키는 다양한 자동화 기능을 제공합니다:

### 🏷️ 완전 자동화된 버전 관리
- 코드 푸시 시 **자동으로 패치 버전 증가** (1.0.0 → 1.0.1)
- 프로젝트 타입별 **적절한 버전 파일 자동 감지 및 업데이트**
- 다양한 환경(Spring, Flutter, React Native 등) 지원
- 버전 충돌 시 **자동으로 높은 버전으로 통합**
- Git 태그 자동 생성 및 관리

### 📝 AI 기반 체인지로그 생성
- **CodeRabbit AI** 리뷰 내용 기반 자동 체인지로그 생성
- 변경 사항 카테고리 자동 분류 (Features, Bug Fixes, Docs 등)
- JSON 및 마크다운 형식 동시 지원 (CHANGELOG.json, CHANGELOG.md)
- PR 내용 자동 파싱 및 체계적 문서화

### 🔄 Pull Request 자동화
- 체인지로그 기반 PR 자동 생성 및 관리
- 리뷰 후 자동 머지 기능
- 코드 품질 검증 자동화

### 🛠️ 배포 파이프라인 통합
- 프로젝트 타입별 맞춤 빌드 프로세스
- 자동 테스트 및 결과 리포팅
- 환경별(개발, 테스트, 운영) 설정 파일 자동 관리

### 🏷️ 이슈 관리 시스템
- **이슈 템플릿** 자동 설정 및 관리
- **이슈 라벨 자동 동기화** 기능
- 저장소 간 일관된 이슈 관리 환경 제공

### 📊 배포 상태 모니터링
- 배포 과정 실시간 추적
- 배포 성공/실패 자동 알림
- README 버전 정보 자동 업데이트

## ⚠️ 시작하기 전에

이 템플릿을 사용하기 위한 필수 준비사항:

1. **GitHub Personal Access Token** 생성
   - 이름: `_GITHUB_PAT_TOKEN`
   - **반드시 classic 키로 생성해야 함** (fine-grained 토큰 아님)
   - 필요 권한: `repo`, `workflow`
   - GitHub Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
   - 생성 후 Repository Settings → Secrets → New repository secret에 등록

2. **Organization 설정 확인** (Organization 저장소인 경우)
   - Settings → Actions → General → Allow GitHub Actions to create and approve pull requests (활성화)
   - Settings → General → Pull Requests → Allow auto-merge (활성화)
   - Settings → Member privileges → Personal access token expiration policy (적절히 설정)
   - **경고**: Organization 설정에 따라 auto-merge, PAT 키 사용, workflow에서 merge 기능 등이 제한될 수 있음

3. **브랜치 구조 설정**
   - `main`: 기본 개발 브랜치
   - `deploy`: 배포용 브랜치 (반드시 생성 필요)
   - **필수**: deploy 브랜치에 모든 CI/CD 워크플로우 파일이 존재해야 합니다
   - **주의**: 프로젝트의 default 브랜치가 `main`이 아닌 경우 워크플로우 파일에서 모든 `main` 참조를 해당 브랜치명으로 변경해야 함

## 🚀 프로젝트 초기 설정

1. **필요 파일 복사**

   ```
   .github/               # 워크플로우 및 스크립트 디렉토리
   version.yml            # 프로젝트 버전 정보 파일
   .coderabbit.yaml       # CodeRabbit AI 설정 파일 (선택)
   ```

   - 위 3개 파일만 복제하면 됩니다. 또한 `README.md`에 버전 표시 영역(아래 "README 버전 자동 업데이트 설정" 참고)을 포함하세요.

<img width="186" height="269" alt="image" src="https://github.com/user-attachments/assets/7fbaacf7-3710-416a-b7a7-a4af84cafd48" />


2. **version.yml 설정**
   ```yaml
   # 필수 설정
   version: "1.0.0"              # 시작 버전
   project_type: "spring"        # 프로젝트 타입 선택
   ```

3. **지원 프로젝트 타입**
   - `spring`: Spring Boot / Java / Gradle 프로젝트
   - `flutter`: Flutter / Dart 프로젝트
   - `react`: React.js 웹 프로젝트
   - `react-native`: React Native 모바일 프로젝트
   - `react-native-expo`: Expo 기반 React Native 프로젝트
   - `node`: Node.js 서버 프로젝트
   - `python`: Python 프로젝트
   - `basic`: 기본 타입 (version.yml만 사용)

## 💻 기존 프로젝트에 통합하기

1. 프로젝트 버전 동기화
   - `version.yml`의 버전과 프로젝트 실제 버전 파일 동기화 필요
   - 예: Spring은 `build.gradle`, Flutter는 `pubspec.yaml`의 버전과 version.yml의 버전을 동일시해주세요
   - **경고**: 버전이 다른 경우 자동으로 높은 버전으로 동기화됩니다

2. 브랜치 설정
   ```bash
   # main 브랜치 (이미 존재)
   
   # deploy 브랜치 생성
   git checkout -b deploy
   git push origin deploy
   ```

3. GitHub 저장소 설정
   - Settings → Branches → Add branch protection rule
   - 두 브랜치(`main`, `deploy`) 모두 보호 설정 권장

## 📋 워크플로우 트리거

| 브랜치 | 이벤트 | 동작 |
|--------|--------|------|
| `main` | push | 버전 자동 증가 + Git 태그 |
| `deploy` | PR | 체인지로그 생성 + 자동 배포 |
| `test` | PR | 빌드 테스트 + 결과 댓글 |

**중요**: `main`과 `deploy` 브랜치 모두에 모든 워크플로우 파일이 존재해야 합니다. 특히 `deploy` 브랜치에 누락된 CI/CD 파일이 있으면 자동화 시스템이 제대로 작동하지 않습니다.

- 자동 체인지로그(PR→deploy 트리거)는 변경사항을 `main` 브랜치로 커밋/푸시합니다.
- README 버전 자동 업데이트(deploy 푸시 트리거)는 `deploy`와 `main` 모두로 푸시합니다.

## ⚙️ 자동화 설정 가이드

### README 버전 자동 업데이트 설정
README.md 파일에 버전 정보가 자동으로 업데이트되려면 다음 형식을 정확히 따라야 합니다:

```markdown
<!-- 수정하지마세요 자동으로 동기화 됩니다 -->
## 최신 버전 : v1.0.4 (2025-08-20)
```

## 🔧 스크립트 사용법

### version_manager.sh

버전 관리를 위한 쉘 스크립트

```bash
# 현재 버전 확인
.github/scripts/version_manager.sh get

# 패치 버전 증가 (1.0.0 → 1.0.1)
.github/scripts/version_manager.sh increment

# 특정 버전으로 설정
.github/scripts/version_manager.sh set 2.0.0
```

### changelog_manager.py

통합 체인지로그 스크립트

```bash
# CodeRabbit Summary HTML 파싱 → CHANGELOG.json 갱신 (워크플로우 내부에서 사용)
python3 .github/scripts/changelog_manager.py update-from-summary

# CHANGELOG.md 재생성
python3 .github/scripts/changelog_manager.py generate-md

# 특정 버전 릴리즈 노트 추출
python3 .github/scripts/changelog_manager.py export --version 1.2.3 --output release_notes.txt
```

## ⚠️ 문제 해결

**GitHub 토큰 오류**
```
remote: Permission to ... denied to github-actions[bot]
```
- GitHub Settings → Secrets에 `_GITHUB_PAT_TOKEN` 등록 확인

**스크립트 실행 권한 오류**
```
bash: permission denied: .github/scripts/version_manager.sh
```
```bash
chmod +x .github/scripts/version_manager.sh
chmod +x .github/scripts/changelog_manager.py
```

## 🤝 기여하기
자세한 기여 가이드라인은 [CONTRIBUTING.md](https://github.com/Cassiiopeia/suh-github-template/blob/main/CONTRIBUTING.md)를 참조해주세요.

## 📬 문의사항

- 이메일: chan4760@naver.com
- [이슈 생성하기](https://github.com/Cassiiopeia/suh-github-template/issues/new/choose)
