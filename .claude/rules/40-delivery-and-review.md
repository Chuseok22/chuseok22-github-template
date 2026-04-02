# Delivery And Review

## Report format

- report 단계에서 반드시 포함할 섹션:
  - 변경 목적
  - 변경 파일
  - 위험 요소
  - 검증 결과
  - 남은 이슈

- 보고서 파일 저장 위치 및 명명 규칙:
  - 위치: `.report/` 디렉토리 (없으면 자동 생성)
  - 파일명: `[YYYYMMDD]_[ISSUE#]_[간단한설명].md`
  - 예시: `20260401_#205_주문완료_페이지_개발.md`
  - 날짜: 작업 완료 시점 (YYYYMMDD 형식)
  - 설명: 한글/영문, 단어 구분은 언더스코어

- 보고서 작성 핵심 원칙:
  - **작성자/작성일 필드 절대 포함 금지** — 파일명에 날짜 포함되므로 별도 기록 불필요
  - **AI 도구명 언급 금지** (Claude, GPT, Copilot, Cursor 등)
  - 능동태, 키워드 기반 문장으로 가독성 향상
  - 민감 정보(토큰, 비밀번호, API Key) 발견 시 `{TOKEN}`, `{API_KEY}`, `{PASSWORD}` 형식으로 마스킹

- 보고서 구조:

  ```markdown
  ### 📌 작업 개요
  [2-3줄 요약]

  ### 🎯 구현 목표 (기능 구현) 또는 🔍 문제 분석 (버그 수정)
  [목적 또는 문제 원인]

  ### ✅ 구현 내용

  #### [주요 변경사항 1]
  - **파일**: `경로/파일명`
  - **변경 내용**: [구체적인 설명]
  - **이유**: [왜 이렇게 수정했는지]

  ### 🔧 주요 변경사항 상세
  [코드 변경 내용을 자연스럽게 설명. 특이사항 포함]

  ### 🧪 검증 결과
  [lint, build, 테스트 결과. PASS/FAIL 명시]

  ### ⚠️ 위험 요소
  [없으면 "없음" 명시]

  ### 📌 남은 이슈
  [후속 작업, 미검증 경로, TODO 등]
  ```

- 작성 스타일 기준:

  **좋은 예:**
  ```
  "gitignore 중복 항목 추가 문제 확인. 정규화 함수 추가하여 중복 체크 로직 구현"
  "주문 저장 실패 시 에러 모달 노출 처리 누락 확인. onError 핸들러 추가로 수정"
  ```

  **나쁜 예:**
  ```
  "중복 항목 추가 문제가 확인되었습니다. 정규화 함수가 생성되었습니다."  # 수동태 금지
  "Claude가 분석한 결과..."  # AI 이름 금지
  "작성자: Claude Code"  # 작성자 필드 금지
  ```

- 보고서 분석 프로세스:
  1. `git status` 한 번만 실행 → 변경된 파일명 확인
  2. 이슈 내용 기반으로 관련 파일만 선별
  3. 선별된 파일을 직접 읽어서 변경 내용 분석
  4. 이후 추가 git 명령어 사용 금지 (토큰 낭비)

## Pull request expectations

- PR 제목 규칙:
  - 형식: `[브랜치명] : [타입] : [설명] [이슈링크]`
  - 타입: `feat` (기능), `fix` (버그), `refactor`, `chore`, `docs`
  - 예시: `주문_완료_페이지_개발 : feat : OrderDetailPage 컴포넌트 추가 https://github.com/waitee-v2/waitee-v2-fe/issues/205`
  - 현재 프로젝트의 실제 커밋 메시지 패턴 참고: `git log` 확인

- PR 본문 구조:
  - `.report/` 에 저장된 보고서 내용을 기반으로 작성
  - 변경 목적, 주요 변경 파일, 검증 결과 포함
  - 스크린샷 (UI 변경 시)

- reviewer 지정 방식:
  - 팀 내 규칙에 따름 (미정의)

- linked issue 규칙:
  - PR 제목 또는 본문에 이슈 URL 포함
  - 현재 패턴: `https://github.com/waitee-v2/waitee-v2-fe/issues/[번호]`

## Delivery constraints

- 배포 전 확인 사항:
  - `npm run lint` — 0 errors
  - `npm run build` — TypeScript 에러 없음, 빌드 성공
  - (테스트 도입 후) `npx vitest run` — 전체 PASS
  - Capacitor 빌드: `npx cap sync` → 네이티브 프로젝트 동기화
  - 환경변수 (`VITE_API_BASE_URL`, `VITE_IMAGE_BASE_URL`, 결제 URL) 설정 확인

- feature flag 정책:
  - 현재 미사용. 필요 시 도입 기준:
    - 완성되지 않은 기능이 main 브랜치에 머지되어야 하는 경우
    - A/B 테스트가 필요한 경우

- rollback 필요 시 기준:
  - 결제 흐름 (PG, PAYCO, Voucher) 에서 오류 발생 시 즉시 롤백
  - 인증(로그인, 토큰) 흐름 장애 시 즉시 롤백
  - 앱 크래시 또는 빈 화면 발생 시 즉시 롤백
  - 롤백 방법: 이전 커밋으로 revert PR 생성
