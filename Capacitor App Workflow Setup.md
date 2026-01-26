# Capacitor CI/CD Secrets 발급 가이드 + Next.js(Capacitor) 초기 세팅

이 문서는 아래 두 워크플로에서 사용되는 **모든 GitHub Actions Secrets**를 대상으로, **발급/생성 방법**, **base64(.b64 파일) 생성 방법**, **GitHub Secrets 등록 방법**, 그리고 **Next.js + Capacitor 초기 세팅(로컬 1회 작업 포함)** 을 정리한다.

- `capactor-build.yml` (Android/iOS 빌드 + Release 업로드)
- `capactor-upload.yml` (Google Play Internal + TestFlight 업로드)

---

## 0. Secrets 전체 목록 (워크플로 기준)

### Android (Build 단계)
| Secret 이름 | 의미 | 형식 |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Android keystore 파일을 base64로 인코딩한 문자열 | `.b64` 파일 내용(단일 라인 권장) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 비밀번호(store password) | 문자열 |
| `ANDROID_KEY_ALIAS` | key alias | 문자열 |
| `ANDROID_KEY_PASSWORD` | key password(일반적으로 keystore 패스와 동일하게 두는 경우 많음) | 문자열 |

### iOS (Build 단계)
| Secret 이름 | 의미 | 형식 |
|---|---|---|
| `IOS_CERT_P12_BASE64` | Apple 배포용 인증서(.p12)를 base64로 인코딩한 문자열 | `.b64` 파일 내용 |
| `IOS_CERT_PASSWORD` | `.p12` export 시 설정한 비밀번호 | 문자열 |
| `IOS_PROVISION_PROFILE_BASE64` | Provisioning Profile(.mobileprovision)을 base64로 인코딩한 문자열 | `.b64` 파일 내용 |
| `IOS_KEYCHAIN_PASSWORD` | CI에서 임시 keychain 생성 시 사용할 비밀번호 | 문자열(랜덤 강력) |
| `IOS_TEAM_ID` | Apple Developer Team ID | 문자열(예: `ABCDE12345`) |
| `IOS_BUNDLE_ID` | iOS Bundle Identifier | 문자열(예: `com.waitee.app`) |

### Android 업로드 (Upload 단계)
| Secret 이름 | 의미 | 형식 |
|---|---|---|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Google Play 업로드용 서비스 계정 JSON 키 | JSON 문자열(원문 그대로) |

### iOS 업로드 (Upload 단계)
| Secret 이름 | 의미 | 형식 |
|---|---|---|
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API Key ID | 문자열 |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID | 문자열(UUID) |
| `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` | App Store Connect API Key의 `.p8` 파일 base64 인코딩 문자열 | `.b64` 파일 내용 |

> 참고  
> - `github.token`(= `GITHUB_TOKEN`)은 GitHub가 자동으로 제공하는 토큰이라 별도 Secret 발급이 필요 없다.  
> - 다만 `repository_dispatch` 호출, release asset 업로드 등에는 workflow permissions가 “읽기 전용”이 아니어야 한다. (아래 “GitHub 설정” 참고)

---

## 1. GitHub Actions Secrets 등록 방법

1. GitHub Repository → **Settings**
2. **Secrets and variables** → **Actions**
3. **New repository secret**
4. Name과 Value 입력 후 저장

### base64 값 등록 시 주의사항
- base64 문자열은 **개행이 섞이면** 디코딩 단계에서 실패할 수 있다.
- 따라서 아래 가이드대로 **단일 라인 base64**를 만들고, 그 파일 내용 전체를 Secret 값에 복사/붙여넣기 한다.

---

## 2. Android Secrets 발급 (Keystore + 비밀번호/alias)

### 2.1 Keystore 생성 (`release.keystore`)
Android 앱 서명용 keystore를 생성한다.

#### (권장) 비대화형 생성 예시
```bash
# 작업 폴더
mkdir -p signing/android
cd signing/android

# 아래 값들은 예시. 실제 서비스 값으로 교체.
KEY_ALIAS="waitee"
KEYSTORE_PASSWORD="강력한비번"
KEY_PASSWORD="강력한비번"  # 보통 KEYSTORE_PASSWORD와 동일하게 둠

# keystore 생성
keytool -genkeypair \
  -alias "${KEY_ALIAS}" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -keystore release.keystore \
  -storepass "${KEYSTORE_PASSWORD}" \
  -keypass "${KEY_PASSWORD}" \
  -dname "CN=Waitee, OU=Mobile, O=Waitee, L=Seoul, S=Seoul, C=KR"
```

#### 생성 확인
```bash
keytool -list -v -keystore release.keystore -storepass "${KEYSTORE_PASSWORD}"
```

### 2.2 Keystore를 base64 “문자열”이 아니라 “.b64 파일”로 만들기

#### macOS
```bash
cd signing/android
# -i: input 지정, tr -d '\n': 개행 제거(단일 라인)
base64 -i release.keystore | tr -d '\n' > release.keystore.b64
```

#### Linux (GNU base64)
```bash
cd signing/android
# -w 0: 줄바꿈 없이 출력(단일 라인)
base64 -w 0 release.keystore > release.keystore.b64
```

#### Windows (PowerShell)
```powershell
# 작업 폴더에서 실행
$bytes = [System.IO.File]::ReadAllBytes("release.keystore")
[System.Convert]::ToBase64String($bytes) | Out-File -Encoding ascii release.keystore.b64
```

### 2.3 GitHub Secrets에 등록할 값
- `ANDROID_KEYSTORE_BASE64` : `release.keystore.b64` 파일 내용 전체
- `ANDROID_KEYSTORE_PASSWORD` : 위에서 사용한 `KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS` : 위에서 사용한 `KEY_ALIAS`
- `ANDROID_KEY_PASSWORD` : 위에서 사용한 `KEY_PASSWORD`

---

## 3. iOS Secrets 발급 (배포 인증서 + 프로비저닝 프로파일 + Team/Bundld ID)

iOS는 **Apple Developer Program** 가입 및 앱 ID/프로비저닝 세팅이 선행되어야 한다.

### 3.1 `IOS_TEAM_ID`, `IOS_BUNDLE_ID`
- `IOS_TEAM_ID`  
  - Apple Developer 계정(Developer portal)에서 확인되는 Team ID를 사용한다.
  - 일반적으로 10자리 영문/숫자 조합(`ABCDE12345`) 형태다.
- `IOS_BUNDLE_ID`  
  - Apple Developer → Identifiers(앱 ID)에서 만든 Bundle ID를 사용한다.
  - 예: `com.waitee.app`

> 워크플로에서는 `IOS_BUNDLE_ID`를 **build 단계(ExportOptions.plist)** 와 **upload 단계(검증)** 에서 같이 쓰므로 값이 반드시 일치해야 한다.

---

## 3.2 배포(Distribution) 인증서 생성 → `.p12`로 Export → base64 `.b64` 만들기

### 3.2.1 인증서 생성 개요
1. Mac에서 Keychain Access(키체인 접근)로 **CSR(인증서 서명 요청)** 생성
2. Apple Developer에서 **Apple Distribution certificate** 발급
3. 발급받은 `.cer`를 더블클릭해서 Keychain에 설치
4. Keychain에서 해당 인증서를 **.p12로 Export** (비밀번호 설정 필수)

### 3.2.2 CSR 생성
1. **Keychain Access** 실행
2. 메뉴: **Certificate Assistant** → **Request a Certificate From a Certificate Authority…**
3. Email Address 입력, Common Name 입력
4. “Saved to disk” 선택 → CSR 파일 저장

### 3.2.3 Apple Developer에서 Distribution Certificate 발급
1. Apple Developer portal 접속
2. Certificates → “+”
3. **Apple Distribution** 선택
4. CSR 업로드
5. 생성된 인증서 다운로드(.cer)

### 3.2.4 .cer 설치
- 다운로드 받은 `.cer` 파일을 더블클릭 → Keychain에 등록된다.

### 3.2.5 .p12 Export
1. Keychain Access에서 “My Certificates”로 이동
2. “Apple Distribution: …” 항목 선택(개인키가 붙어있는 항목이어야 함)
3. 우클릭 → Export
4. 파일 형식: `.p12`
5. **Export 비밀번호 설정** (이 값이 `IOS_CERT_PASSWORD`)

### 3.2.6 `.p12`를 base64 `.b64` 파일로 만들기

#### macOS
```bash
mkdir -p signing/ios
cd signing/ios

# 예: dist.p12 라는 이름으로 저장했다고 가정
base64 -i dist.p12 | tr -d '\n' > dist.p12.b64
```

#### Linux
```bash
mkdir -p signing/ios
cd signing/ios
base64 -w 0 dist.p12 > dist.p12.b64
```

#### GitHub Secrets 등록
- `IOS_CERT_P12_BASE64` : `dist.p12.b64` 내용 전체
- `IOS_CERT_PASSWORD` : p12 export 시 설정한 비밀번호

---

## 3.3 Provisioning Profile 생성 → `.mobileprovision` 다운로드 → base64 `.b64` 만들기

### 3.3.1 Provisioning Profile 생성 개요
1. Apple Developer portal → Profiles → “+”
2. Distribution(App Store) 프로파일 선택
3. App ID(= Bundle ID) 선택
4. Distribution 인증서 선택
5. (필요시) Devices는 App Store 배포에서는 보통 필요 없음
6. 프로파일 생성 후 다운로드(.mobileprovision)

### 3.3.2 `.mobileprovision`을 base64 `.b64` 파일로 만들기

#### macOS
```bash
cd signing/ios
base64 -i AppStoreProfile.mobileprovision | tr -d '\n' > AppStoreProfile.mobileprovision.b64
```

#### Linux
```bash
cd signing/ios
base64 -w 0 AppStoreProfile.mobileprovision > AppStoreProfile.mobileprovision.b64
```

#### GitHub Secrets 등록
- `IOS_PROVISION_PROFILE_BASE64` : `AppStoreProfile.mobileprovision.b64` 내용 전체

---

## 3.4 `IOS_KEYCHAIN_PASSWORD` 생성(랜덤 강력 비밀번호)
워크플로에서 아래처럼 임시 keychain을 만들 때 사용한다.
```bash
security create-keychain -p "$KEYCHAIN_PASSWORD" ...
```

권장 생성 방식(로컬):
```bash
# macOS/Linux
openssl rand -base64 32 | tr -d '\n'
```

- 생성된 문자열을 GitHub Secret `IOS_KEYCHAIN_PASSWORD`로 등록한다.

---

## 4. App Store Connect API Key 발급 (Upload 단계 / TestFlight)

워크플로의 `fastlane pilot upload --api_key_path ...`는 **App Store Connect API Key** 기반으로 인증한다.

필요 Secrets:
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` (p8 파일 base64)

### 4.1 App Store Connect에서 API Key 생성
1. App Store Connect 접속
2. Users and Access → **Keys** 탭
3. “+”로 새 Key 생성
4. Role은 업로드/배포 가능한 권한 선택 (권한 부족하면 업로드 실패)
5. 생성 후 **.p8 파일을 한 번만 다운로드 가능**  
   - 다운로드 즉시 안전한 위치에 저장

### 4.2 Key ID / Issuer ID 확인
- Key 생성 화면에 `Key ID`가 표시된다 → `APP_STORE_CONNECT_KEY_ID`
- 화면 상단 혹은 API Key 페이지에 `Issuer ID`가 표시된다 → `APP_STORE_CONNECT_ISSUER_ID`

### 4.3 `.p8`를 base64 `.b64` 파일로 만들기

#### macOS
```bash
mkdir -p signing/appstoreconnect
cd signing/appstoreconnect

# 예: AuthKey_XXXXXXXXXX.p8
base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n' > AuthKey_XXXXXXXXXX.p8.b64
```

#### Linux
```bash
mkdir -p signing/appstoreconnect
cd signing/appstoreconnect
base64 -w 0 AuthKey_XXXXXXXXXX.p8 > AuthKey_XXXXXXXXXX.p8.b64
```

#### GitHub Secrets 등록
- `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` : `.p8.b64` 파일 내용 전체
- `APP_STORE_CONNECT_KEY_ID` : Key ID 문자열
- `APP_STORE_CONNECT_ISSUER_ID` : Issuer ID 문자열

---

## 5. Google Play Service Account JSON 발급 (Upload 단계 / Internal Track)

워크플로의 `r0adkll/upload-google-play`는 서비스 계정 JSON 키가 필요하다.

필요 Secret:
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (JSON 원문 문자열)

### 5.1 Google Play Console에서 API Access 연결(개요)
1. Google Play Console 접속
2. Setup → **API access**
3. Google Cloud Project 연결(없으면 생성)
4. 해당 Cloud Project에서 Service Account 생성
5. Service Account에 JSON Key 발급(다운로드)
6. Play Console에서 해당 Service Account에 앱 권한 부여

### 5.2 Service Account 생성 + JSON Key 다운로드(권장 흐름)
1. Google Cloud Console → IAM & Admin → Service Accounts
2. “Create service account”
3. 생성 후 Keys 탭 → “Add key” → “Create new key” → JSON 선택
4. JSON 파일 다운로드

### 5.3 Play Console에 Service Account 권한 부여
- Play Console → Users and permissions에서 서비스 계정을 사용자로 추가하고,
  - Internal track 업로드가 가능한 권한(릴리즈 관리/업로드 권한)을 부여한다.
- 권한이 부족하면 액션에서 업로드 단계가 실패한다.

### 5.4 GitHub Secret에 JSON 등록
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`에 **JSON 파일의 전체 내용**을 그대로 복사/붙여넣기 한다.
- base64로 만들 필요 없다(워크플로는 JSON plain text를 기대).

> 운영 팁  
> - JSON 안에는 `private_key`에 개행(`\n`)이 포함된다. GitHub Secrets는 이 형태를 그대로 저장할 수 있다.  
> - 복사/붙여넣기 시 JSON이 손상되지 않게 주의한다.

---

## 6. Next.js 환경에서 Capacitor 초기 세팅 (로컬 1회 작업 포함)

전제:
- Next.js는 `next.config.ts`에 `output: "export"`를 사용하고,
- CI에서는 `npm run build` 결과물이 `out/`에 생성되어야 한다.
- Capacitor는 `webDir`을 `out`으로 바라본다.

### 6.1 의존성 설치
프로젝트 루트에서 실행:

```bash
npm i @capacitor/core @capacitor/cli
npm i -D @capacitor/assets
npm i @capacitor/android @capacitor/ios
```

> iOS는 macOS에서만 빌드/실행 가능하다.

### 6.2 `capacitor.config.ts` 생성/초기화
```bash
npx cap init
```

예시(`capacitor.config.ts`):
```ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.waitee.app',
  appName: 'Waitee',
  webDir: 'out',
  bundledWebRuntime: false
};

export default config;
```

### 6.3 플랫폼 추가 (로컬 1회)
```bash
npx cap add android
npx cap add ios
```

### 6.4 Next.js 정적 export 설정 확인 (`next.config.ts`)
`output: "export"` 사용 시 흔히 함께 넣는 옵션:

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  images: { unoptimized: true },
  trailingSlash: true
};

export default nextConfig;
```

- Capacitor WebView에서는 Next Image 최적화 서버가 없으므로 `unoptimized: true`가 안전하다.
- `trailingSlash: true`는 라우팅/정적 파일 경로에서 문제를 줄이는 경우가 많다.

### 6.5 로컬에서 “빌드 → sync” 흐름 (반드시 한 번 확인)
Capacitor sync는 `webDir(out/)`가 존재해야 한다.

```bash
npm run build
npx cap sync
```

플랫폼별:
```bash
# Android만
npx cap sync android

# iOS만
npx cap sync ios
```

### 6.6 플랫폼 IDE로 열기 (개발/디버그용)
```bash
npx cap open android
npx cap open ios
```

### 6.7 iOS 로컬 준비물(1회)
- Xcode 설치
- CocoaPods 설치(필요 시)
```bash
sudo gem install cocoapods
pod --version
```

### 6.8 Android 로컬 준비물(1회)
- Android Studio 설치
- SDK / Build-tools 설치
- `JAVA_HOME`(JDK 21) 정리

---

## 7. 로컬에서 Secrets 값 검증(권장)

### 7.1 Android keystore base64 검증
```bash
# b64 파일에서 keystore 복원
cat signing/android/release.keystore.b64 | base64 --decode > /tmp/release.keystore

# 목록 조회
keytool -list -v -keystore /tmp/release.keystore -storepass "KEYSTORE_PASSWORD"
```

(macOS에서 `base64 --decode`가 동작하지 않으면 `base64 -D` 사용)
```bash
cat signing/android/release.keystore.b64 | base64 -D > /tmp/release.keystore
```

### 7.2 iOS p12 base64 검증
```bash
cat signing/ios/dist.p12.b64 | base64 --decode > /tmp/dist.p12
```

---

## 8. 보안 운영 원칙(권장)
- keystore/p12/p8 원본 파일은 **절대 git에 커밋하지 않는다.**
- `.b64` 파일도 원칙적으로는 커밋하지 않는다(로컬에서 생성 후 폐기).
- 비밀번호는 재사용하지 않고, 최소 32자 랜덤을 권장한다.
- 서비스 계정 권한은 “필요 최소”로 부여한다.

---

## 9. 빠른 체크리스트

### Android
- [ ] `release.keystore` 생성
- [ ] `release.keystore.b64` 생성(단일 라인)
- [ ] `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` 등록

### iOS (Build)
- [ ] Apple Distribution 인증서 발급 + Keychain 설치
- [ ] `.p12` export + 비밀번호 설정
- [ ] `.p12.b64` 생성(단일 라인) → `IOS_CERT_P12_BASE64`, `IOS_CERT_PASSWORD`
- [ ] App Store Provisioning Profile 다운로드
- [ ] `.mobileprovision.b64` 생성(단일 라인) → `IOS_PROVISION_PROFILE_BASE64`
- [ ] `IOS_KEYCHAIN_PASSWORD` 생성/등록
- [ ] `IOS_TEAM_ID`, `IOS_BUNDLE_ID` 등록

### iOS (Upload)
- [ ] App Store Connect API Key 생성
- [ ] `.p8` 다운로드(1회) + `.p8.b64` 생성
- [ ] `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` 등록

### Google Play (Upload)
- [ ] Service Account 생성 + JSON Key 다운로드
- [ ] Play Console에서 권한 부여
- [ ] `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` 등록(JSON 원문)

---

## 부록: 자주 하는 실수
- `base64` 결과에 개행이 포함되어 디코딩 실패 → **단일 라인 b64 파일로 만들기**
- `IOS_BUNDLE_ID`가 빌드/업로드/Apple 설정에서 서로 다름 → 전부 동일해야 함
- Play Console에서 서비스 계정 권한이 부족함 → 업로드 단계에서 403/권한 오류
- upload.yml concurrency에서 `workflow_run` 컨텍스트를 참조함 → repository_dispatch에서는 없음
