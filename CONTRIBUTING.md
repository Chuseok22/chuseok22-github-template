# 기여 가이드라인

GitHub 자동화 템플릿 프로젝트에 기여해주셔서 감사합니다! 이 문서는 기여자들이 프로젝트에 효과적으로 참여할 수 있도록 안내합니다.

## 기여 절차

1. 먼저 [이슈](https://github.com/Cassiiopeia/suh-github-template/issues)를 확인하여 이미 보고된 문제인지 확인해주세요.
2. 새로운 기능이나 개선 사항을 제안하려면 먼저 이슈를 생성하여 논의해주세요.
3. 코드 기여 전에 프로젝트 구조와 워크플로우를 이해해주세요.

## 개발 환경 설정

1. 저장소를 포크하고 클론합니다:
   ```bash
   git clone https://github.com/YOUR-USERNAME/suh-github-template.git
   cd suh-github-template
   ```

2. 원격 저장소를 추가합니다:
   ```bash
   git remote add upstream https://github.com/Cassiiopeia/suh-github-template.git
   ```

3. 최신 변경사항을 동기화합니다:
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

## 브랜치 전략

- `main`: 개발 브랜치
- `deploy`: 배포 브랜치
- 기능 브랜치: `feature/기능명`
- 버그 수정 브랜치: `fix/버그명`
- 문서 수정 브랜치: `docs/설명`

## 커밋 메시지 가이드라인

커밋 메시지는 다음 형식을 따라주세요:

```
<타입>: <제목>

<본문>

<꼬리말>
```

### 타입

- `feat`: 새 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 변경
- `style`: 코드 포맷팅, 세미콜론 누락 등 (코드 변경 없음)
- `refactor`: 코드 리팩토링
- `test`: 테스트 코드 추가 또는 수정
- `chore`: 빌드 프로세스, 라이브러리 업데이트 등 변경

### 예시

```
feat: 자동 버전 업데이트 기능 추가

버전 관리 스크립트에 자동으로 README.md 파일의 버전 정보를 업데이트하는 기능을 추가합니다.
이 기능은 deploy 브랜치로 푸시할 때 자동으로 실행됩니다.

Closes #42
```

## Pull Request 프로세스

1. 작업할 이슈를 선택하거나 새로운 이슈를 생성합니다.
2. 새 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`).
3. 코드를 변경하고 커밋합니다.
4. 원격 저장소에 푸시합니다 (`git push origin feature/amazing-feature`).
5. GitHub에서 Pull Request를 생성합니다.
6. PR 템플릿을 작성하고 관련 이슈를 연결합니다.
7. 코드 리뷰 후 필요한 수정을 진행합니다.
8. 모든 검토가 완료되면 PR이 병합됩니다.

## 코드 스타일

- 쉘 스크립트: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)를 따릅니다.
- Python: [PEP 8](https://www.python.org/dev/peps/pep-0008/)을 따릅니다.
- YAML: 2칸 들여쓰기를 사용합니다.

## 테스트

- 모든 새로운 기능과 버그 수정에는 적절한 테스트가 포함되어야 합니다.
- 테스트는 다양한 환경에서 실행되어야 합니다.

## 문서화

- 새로운 기능이나 변경사항은 적절히 문서화되어야 합니다.
- README.md, 인라인 코드 주석, 그리고 필요한 경우 추가 문서를 업데이트해주세요.

## 이슈 및 PR 템플릿

이슈와 PR을 생성할 때는 제공된 템플릿을 사용해주세요. 템플릿은 다음 위치에 있습니다:

- 이슈 템플릿: `.github/ISSUE_TEMPLATE/`
- PR 템플릿: `.github/PULL_REQUEST_TEMPLATE.md`

## 라이센스

이 프로젝트에 기여함으로써, 귀하는 귀하의 기여가 프로젝트의 MIT 라이센스 하에 배포됨에 동의합니다.

## 질문이나 도움이 필요하신가요?

질문이나 도움이 필요하시면 [이슈](https://github.com/Cassiiopeia/suh-github-template/issues)를 생성하거나 메인테이너에게 이메일(chan4760@naver.com)로 문의해주세요.

감사합니다!
