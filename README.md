# 🚀 GitHub 자동화 템플릿

다양한 프로젝트 타입에서 **버전 관리**, **체인지로그 생성**, **빌드 테스트**, **배포**를 자동화하는 GitHub Actions 워크플로우 템플릿입니다.

## 📋 지원 프로젝트 타입

- **Spring Boot** (`spring`) - Java/Gradle
- **React Native** (`react-native`) - JavaScript/TypeScript  
- **React Native Expo** (`react-native-expo`) - Expo 프레임워크
- **React** (`react`) - 웹 프로젝트
- **Flutter** (`flutter`) - Dart/모바일
- **Node.js** (`node`) - 서버 프로젝트
- **Python** (`python`) - Python 프로젝트

## 🔧 주요 기능

### 1. 🏷️ 자동 버전 관리
- `main` 브랜치 푸시 시 **patch 버전 자동 증가** (1.0.0 → 1.0.1)
- 프로젝트별 버전 파일 자동 업데이트 (build.gradle, package.json, pubspec.yaml 등)
- Git 태그 자동 생성

### 2. 📝 체인지로그 자동 생성
- `deploy` 브랜치 PR 시 **CodeRabbit AI 리뷰 감지**
- CHANGELOG.json/CHANGELOG.md 자동 생성
- PR 자동 머지 후 배포 트리거

### 3. 🧪 빌드 테스트
- `test` 브랜치 PR 시 프로젝트 타입별 빌드 테스트
- 테스트 결과 PR 댓글 자동 작성

### 4. 📤 설정 파일 관리
- GitHub Secrets → 서버 자동 업로드
- 환경별 설정 파일 백업 관리

### 5. 🏷️ 이슈 라벨 동기화
- GitHub 이슈 라벨 자동 동기화

## 🚀 빠른 시작

### 1. 프로젝트 설정
```yaml
# version.yml (프로젝트 루트에 생성)
version: "1.0.0"
project_type: "react-native-expo"  # 사용할 프로젝트 타입
```

### 2. GitHub Secrets 설정 (필요시)
```
APPLICATION_PROD_YML: Spring Boot 설정 파일
ENV_FILE: React/RN .env 파일
SERVER_HOST: 서버 호스트 (자동 업로드용)
SERVER_USER: SSH 사용자명
SERVER_PASSWORD: SSH 비밀번호
```

### 3. 워크플로우 동작
```
코드 수정 → main 푸시 → 버전 자동 증가 → Git 태그 생성
배포 준비 → deploy PR → CodeRabbit 리뷰 → 체인지로그 생성 → 자동 배포
테스트 → test PR → 빌드 테스트 → 결과 댓글
```

## 📁 주요 파일

```
.github/workflows/
├── PROJECT-VERSION-CONTROL.yaml          # 버전 자동 관리
├── PROJECT-AUTO-CHANGELOG-CONTROL.yaml   # 체인지로그 생성
├── PROJECT-CI-SPRING-TEST.yaml          # 빌드 테스트
├── PROJECT-CONFIG-SYNOLOGY-AUTO-UPLOAD.yaml # 설정 파일 업로드
└── PROJECT-DEPLOY-TRIGGER-VERIFICATION.yaml # 배포 확인

scripts/version-manager.sh    # 버전 관리 스크립트
version.yml                  # 프로젝트 설정
```

## 🛠️ 사용 예시

### React Native Expo 프로젝트
현재 이 템플릿은 React Native Expo 프로젝트로 설정되어 있습니다:
- **현재 버전**: 1.2.4
- **버전 파일**: app.json
- **빌드 번호**: 자동 증가

### Spring Boot 프로젝트로 변경하려면
```yaml
# version.yml
project_type: "spring"
```

### Flutter 프로젝트로 변경하려면
```yaml
# version.yml  
project_type: "flutter"
```

## 📋 워크플로우 트리거

| 브랜치 | 이벤트 | 동작 |
|--------|--------|------|
| `main` | push | 버전 자동 증가 + Git 태그 |
| `deploy` | PR | 체인지로그 생성 + 자동 배포 |
| `test` | PR | 빌드 테스트 + 결과 댓글 |

## 🔧 문제 해결

**Q: 버전이 업데이트되지 않아요**
```bash
chmod +x scripts/version-manager.sh  # 실행 권한 확인
```

**Q: CodeRabbit 리뷰가 감지되지 않아요**
A: deploy 브랜치 PR 생성 후 CodeRabbit이 리뷰를 작성할 때까지 최대 10분 대기합니다.

**Q: 특정 프로젝트 타입을 추가하고 싶어요**
A: `version.yml`의 `project_configs`에 새 타입을 추가하고 `version-manager.sh`를 수정하세요.

## 📝 라이센스

MIT 라이센스 - 자유롭게 사용, 수정, 배포 가능합니다.

---

**⭐ 이 템플릿이 도움이 되셨다면 Star를 눌러주세요!**
