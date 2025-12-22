--- Cursor Command: init.md ---
# Init Command - 일감 초기화 자동화

당신은 Redmine 일감을 자동으로 파싱하고 작업 폴더를 생성하는 전문가입니다.

## 🎯 핵심 목표
1. 사용자가 제공한 Redmine 웹페이지 내용을 파싱
2. 일감 번호와 제목을 추출하여 브랜치명 생성
3. 템플릿 폴더를 복사하고 브랜치명으로 변경
4. 내부 템플릿 파일 자동 작성

## 📋 작업 프로세스

### 1단계: Redmine 페이지 파싱
사용자가 제공한 HTML 텍스트에서 다음 정보를 추출:

**추출 필드**
- **일감 번호**: `기능요청 #202027` 형태에서 `202027` 추출
- **일감 제목**: 대괄호로 시작하는 제목 전체 (예: `[CM] MAToolDaemon.jar 기동 시 crontab SMSScheduler 라인 제거 개선 요청의 건`)
- **일감 유형**: `기능요청`, `시험요청`, `업무요청` 등
- **담당자**: 개발담당 필드 값
- **목표버전**: Privacy-i, DB-i 등 제품명

**파싱 규칙**
```
일감 번호: "기능요청 #", "시험요청 #", "업무요청 #" 다음에 오는 숫자
일감 제목: 설명 섹션 직전의 대괄호로 시작하는 한 줄 제목
개발담당: "개발담당:" 라벨 다음 값
```

### 2단계: 브랜치명 생성 규칙
**@Somansa - 브랜치명 생성기.txt 규칙 적용**

**형식**: `[날짜]_[#일감번호]_[일감제목]`

**상세 규칙**
1. **날짜**: `YYYYMMDD` 형식 (오늘 날짜 사용)
2. **일감 번호**: `#` 포함하여 표기 (예: `#202027`)
3. **일감 제목 변환**:
   - 대괄호 `[]`, 소괄호 `()` 제거하지 않음 (원본 유지)
   - 공백은 언더스코어 `_`로 변환
   - 슬래시 `/` 는 그대로 유지하거나 언더스코어로 변환
   - 특수문자 제거: `:`, `,`, `.`, `?`, `!` 등

**예시**
```
입력: 기능요청 #202027
      [CM] MAToolDaemon.jar 기동 시 crontab SMSScheduler 라인 제거 개선 요청의 건
      날짜: 2025년 10월 13일

출력: 20251013_#202027_CM_MAToolDaemon.jar_기동_시_crontab_SMSScheduler_라인_제거_개선_요청의_건
```

### 3단계: 폴더 복사 및 이름 변경
**원본 폴더**: `d:\0-suh\document\19991029_#991029_새찬_템플릿\`
**대상 폴더**: `d:\0-suh\document\[생성된_브랜치명]\`

**작업**
1. 템플릿 폴더 **전체를 그대로** 복사 (모든 파일 포함)
2. 복사된 폴더명을 생성된 브랜치명으로 변경
3. 내부 파일은 **그대로 유지** (PPT, 테스트코드 템플릿 등 모두 보존)

**⚠️ 중요**: Copy-Item -Recurse 옵션을 사용하여 모든 하위 파일 포함하여 복사

### 4단계: B-브랜치, 커밋 제목.txt 파일 작성
**파일 경로**: `[새_폴더]\B-브랜치, 커밋 제목.txt`

**작성 내용**
```
1. 브랜치 이름

[생성된 브랜치명]

2. 커밋 메시지

[커밋 메시지 형식: [일감 제목] : [타입] : [설명] [이슈 URL]]

3. 기능정의서 문서 제목

FD-PLAB-[YYYYMMDD]-[일감번호]: [일감 제목]

4. 테스트케이스 문서 제목

DTR-PLAB-[YYYYMMDD]-[일감번호]: [일감 제목] - 개발자 테스트

```

**커밋 메시지 생성 규칙**
- **형식**: `[일감제목] : [타입] : [변경사항 설명] http://redmine.somansa.com/redmine/issues/[일감번호]`
- **타입 판단**:
  - 신규 기능: `feat`
  - 버그 수정/개선: `fix`
  - 리팩토링: `refactor`
  - 문서: `docs`
- **일감 제목**: 대괄호 내용 제거 (예: `[CM]` 제거)
- **설명**: AI가 일감 내용을 분석하여 **구체적인 예시 작성**
  - 일감 제목과 설명을 바탕으로 핵심 변경사항을 한 줄로 요약
  - 예: "root/somansa 계정 crontab 라인 중복 제거 로직 추가"
  - 예: "System Overview 서비스 상태 체크 기능 개선"
  - 예: "로그다운로더 설정 파일 생성 제한 기능 구현"

**예시**
```
1. 브랜치 이름

20251013_#202027_CM_MAToolDaemon.jar_기동_시_crontab_SMSScheduler_라인_제거_개선_요청의_건

2. 커밋 메시지

CM MAToolDaemon.jar 기동 시 crontab SMSScheduler 라인 제거 개선 요청의 건 : feat : root와 somansa 계정 crontab SMSScheduler 중복 라인 자동 제거 기능 추가 http://redmine.somansa.com/redmine/issues/202027

3. 기능정의서 문서 제목

FD-PLAB-20251013-202027: [CM] MAToolDaemon.jar 기동 시 crontab SMSScheduler 라인 제거 개선 요청의 건

4. 테스트케이스 문서 제목

DTR-PLAB-20251013-202027: [CM] MAToolDaemon.jar 기동 시 crontab SMSScheduler 라인 제거 개선 요청의 건 - 개발자 테스트

```

**커밋 메시지 설명 작성 가이드**
- 일감의 "개발 요청 배경"과 "기능상세"의 TO-BE를 분석
- 핵심 변경사항을 동사로 시작하는 한 줄로 요약
- 구체적인 기술/모듈명 포함
- 20자 이상, 60자 이하 권장

## 🔧 구현 세부사항

### ⚠️ 중요: 폴더 복사 방법

**PowerShell의 근본적 한계**
Cursor의 PowerShell 래퍼는 한글 경로 처리 시 인코딩 문제가 있습니다:
- 임시 `.ps1` 스크립트 파일 생성 시 ANSI 인코딩 사용
- 명령어 문자열에 한글이 포함되면 126번째 줄에서 파서 에러 발생
- UTF-8 설정 (`chcp 65001`, `$OutputEncoding`) 시도했으나 **근본 해결 불가**
- `Get-Item` + 와일드카드로 원본 경로는 우회 가능하나, 대상 경로 한글은 여전히 실패

브랜치명에 한글(`기동`, `라인`, `제거` 등)이 필수로 포함되므로,
**Python 스크립트 사용이 유일한 안정적 방법**입니다.

### ✅ 권장 방법: common_util.py 사용 (영구 보관)

**Cursor는 `.cursor/scripts/common_util.py`에 재사용 가능한 유틸리티를 제공합니다.**

```python
# .cursor/scripts/common_util.py 모듈 사용
import sys
sys.path.insert(0, r"d:\0-suh\document\.cursor\scripts")
from common_util import copy_folder

# 브랜치명은 파싱된 정보로 생성
branch_name = "YYYYMMDD_#일감번호_일감제목"

source = r"d:\0-suh\document\19991029_#991029_새찬_템플릿"
dest = rf"d:\0-suh\document\{branch_name}"

# 폴더 복사 (자동 검증 포함)
result = copy_folder(source, dest, overwrite=True, verify=True)

if result["success"]:
    print(f"✅ 폴더 복사 완료: {result['dest_path']}")
    print(f"📦 파일 개수: {result['file_count']}개")
else:
    print(f"❌ 복사 실패: {result['error']}")
```

### 실행 방법

**Option 1: 직접 Python 명령어 실행 (권장)**
```bash
python -c "import sys; sys.path.insert(0, r'd:\0-suh\document\.cursor\scripts'); from common_util import copy_folder; result = copy_folder(r'원본경로', r'대상경로'); print(f'Success: {result[\"file_count\"]} files')"
```

**Option 2: 임시 스크립트 생성 방식 (복잡한 로직용)**
```python
# 1. 스크립트 생성
script_content = f'''
import sys
sys.path.insert(0, r"d:\\0-suh\\document\\.cursor\\scripts")
from common_util import copy_folder

result = copy_folder(
    r"d:\\0-suh\\document\\19991029_#991029_새찬_템플릿",
    r"d:\\0-suh\\document\\{branch_name}"
)

print(f"✅ 복사 완료: {{result['file_count']}}개 파일")
'''

write_file("_temp_init.py", script_content)

# 2. 실행
run_terminal_cmd("python _temp_init.py")

# 3. 삭제
delete_file("_temp_init.py")
```

### common_util.py 주요 함수

| 함수 | 설명 | 반환값 |
|------|------|--------|
| `copy_folder(src, dest)` | 폴더 복사 (한글 지원) | Dict (성공 여부, 파일 개수) |
| `delete_folder(path)` | 안전한 폴더 삭제 | bool |
| `ensure_dir(path)` | 디렉토리 생성 | str (절대 경로) |
| `list_files(path, pattern)` | 파일 목록 조회 | List[str] |
| `get_file_info(path)` | 파일 정보 조회 | Dict |
| `safe_file_name(name)` | 안전한 파일명 생성 | str |

**장점**:
- ✅ 재사용 가능 (다른 command에서도 사용)
- ✅ 영구 보관 (삭제되지 않음)
- ✅ 검증 기능 포함 (파일 개수 자동 확인)
- ✅ 에러 처리 내장
- ✅ 문서화된 API

### 파싱 주의사항
- HTML 태그는 무시하고 텍스트만 추출
- 일감 번호는 항상 `#` 뒤의 6자리 숫자
- 제목은 개행 문자 제거 후 한 줄로 처리
- 날짜는 항상 현재 날짜 (YYYYMMDD) 사용
- **설명 섹션**의 "개발 요청 배경", "기능상세", "TO-BE" 내용을 파싱하여 커밋 메시지 설명에 활용

### 에러 처리
- 일감 번호를 찾지 못한 경우: 사용자에게 재입력 요청
- 일감 제목이 비어있는 경우: 사용자에게 재입력 요청
- 이미 동일 이름의 폴더가 존재하는 경우: 덮어쓸지 물어보기

## 📤 출력 형식

작업 완료 후 다음과 같이 보고:

```
✅ 일감 초기화 완료!

📁 생성된 폴더: [브랜치명]
🔢 일감 번호: #[번호]
📝 일감 제목: [제목]

📋 생성된 파일:
  ✓ B-브랜치, 커밋 제목.txt

🎯 다음 단계:
  1. [폴더명]으로 이동하여 작업 시작
  2. B-브랜치, 커밋 제목.txt 내용 확인 및 커밋 메시지 설명 작성
  3. A-개발보고서, 테스트보고서 URL.txt에 문서 링크 추가
```

## 🚨 중요 원칙
- **폴더 복사 완전성**: 템플릿 폴더의 **모든 파일**을 빠짐없이 복사
  - PPT_템플릿.txt
  - new_템플릿_글꼴포함.pptx
  - new_템플릿.pptx
  - C-일감 보고 텍스트 템플릿.txt
  - 테스트코드_템플릿.txt
  - B-브랜치, 커밋 제목.txt (이것만 수정)
  - A-개발보고서, 테스트보고서 URL.txt
- **B-브랜치, 커밋 제목.txt만 수정**: 나머지 파일은 원본 그대로 유지
- **커밋 메시지 설명은 AI가 작성**: `[변경 사항 설명]` 같은 플레이스홀더 금지
- **파일 내용 정확성**: 템플릿 형식을 정확히 준수
- **한글 인코딩**: UTF-8 BOM 없이 저장
- **날짜 정확성**: 한국 시간 기준 (UTC+9)

---
**사용 방법**: `/init` 명령 후 Redmine 웹페이지 전체 내용을 붙여넣으면 자동 처리됩니다.
--- End Command ---

