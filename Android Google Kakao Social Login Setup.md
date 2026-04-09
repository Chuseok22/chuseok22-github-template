# Android 소셜 로그인 설정 가이드

> Google Sign-In, Kakao 로그인 Android 실기기(Google Play 배포 빌드) 기준 전체 설정 절차 및 트러블슈팅 가이드

---

## 📌 목차

1. [전제 조건 — Google Play 앱 서명 이해](#1-전제-조건--google-play-앱-서명-이해)
2. [Google Sign-In 설정](#2-google-sign-in-설정)
3. [Kakao 로그인 설정](#3-kakao-로그인-설정)
4. [Android 네이티브 코드 설정](#4-android-네이티브-코드-설정)
5. [ProGuard 설정](#5-proguard-설정)
6. [CI/CD 환경변수 설정](#6-cicd-환경변수-설정)
7. [최종 체크리스트](#7-최종-체크리스트)
8. [오류별 원인 및 해결](#8-오류별-원인-및-해결)

---

## 1. 전제 조건 — Google Play 앱 서명 이해

Google Play App Signing 환경에서는 **두 가지 서명 키**가 존재하며, 소셜 로그인 설정에 사용하는 키를 **반드시 구분**해야 한다.

```
개발자 로컬
  └── 업로드 키 (Upload Key)
        ↓ AAB 서명 후 Play Console에 업로드
Play Console
  └── 업로드 키 제거 → 앱 서명 키 (App Signing Key)로 재서명
        ↓ 최종 APK를 사용자 기기에 배포
사용자 기기
  └── 앱 서명 키로 서명된 APK 설치
```

**소셜 로그인 설정(Google OAuth, Kakao 키 해시)에는 항상 앱 서명 키 인증서를 사용한다.**

### 앱 서명 키 SHA-1 확인 방법

```
Play Console → [앱 선택] → 설정 → 앱 무결성 → 앱 서명
  → "앱 서명 키 인증서" 섹션의 SHA-1 지문 복사
```

> ⚠️ "업로드 키 인증서" SHA-1은 소셜 로그인 설정에 사용하지 않는다.

---

## 2. Google Sign-In 설정

### 사용 패키지

- `@capgo/capacitor-social-login` v8.3.9
- Credential Manager API (`GetSignInWithGoogleOption`) 기반

### 2-1. GCP Console OAuth 클라이언트 등록

Google Sign-In이 작동하려면 **같은 GCP 프로젝트**에 다음 두 OAuth 클라이언트가 모두 존재해야 한다.

#### Android 타입 클라이언트

```
GCP Console → APIs & Services → OAuth 2.0 클라이언트 ID → 만들기
  → 애플리케이션 유형: Android
  → 패키지 이름: com.waitee.app
  → SHA-1 인증서 지문: [앱 서명 키 인증서 SHA-1 입력]
```

#### Web application 타입 클라이언트

```
GCP Console → APIs & Services → OAuth 2.0 클라이언트 ID → 만들기
  → 애플리케이션 유형: 웹 애플리케이션
```

생성된 Web application 클라이언트 ID를 메모해 둔다.

> ⚠️ **중요**: Android 클라이언트와 Web application 클라이언트가 **반드시 동일한 GCP 프로젝트**에 있어야 한다.  
> 프로젝트가 다르면 `GetCredentialCancellationException`이 발생한다.
>
> GCP 클라이언트 ID 형식: `{프로젝트번호}-{랜덤문자열}.apps.googleusercontent.com`  
> 두 클라이언트 ID의 **프로젝트번호가 동일한지** 반드시 확인한다.

### 2-2. 프로젝트 환경변수 설정

**`VITE_GOOGLE_WEB_CLIENT_ID`**에 Web application 클라이언트 ID를 사용한다.

```bash
# .github/workflows/react-basic-cicd.yml 또는 .env
VITE_GOOGLE_WEB_CLIENT_ID=836964428266-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

### 2-3. 소스 코드 연결

`src/shared/utils/env.ts`:
```typescript
export const GOOGLE_WEB_CLIENT_ID: string = validateEnv(
  import.meta.env.VITE_GOOGLE_WEB_CLIENT_ID,
);
```

`src/features/auth/lib/google/googleSdkAdapter.ts`:
```typescript
await SocialLogin.initialize({
  google: {
    iOSClientId: GOOGLE_IOS_CLIENT_ID,
    webClientId: GOOGLE_WEB_CLIENT_ID, // Web application 클라이언트 ID
  },
});
```

### 2-4. 주의사항

- `webClientId`에 Android 타입 클라이언트 ID를 넣으면 **안 된다**.
- iOS 클라이언트 ID와 Web application 클라이언트 ID는 **별개**이며, iOS에는 iOS 클라이언트 ID를 사용한다.
- OAuth 동의 화면 게시 상태가 "테스트 중"이면 등록된 테스트 사용자만 로그인 가능하다. 전체 배포 시 "프로덕션"으로 전환 필요.

---

## 3. Kakao 로그인 설정

### 사용 패키지

- `@chuseok22/capacitor-kakao-login` v0.2.0
- Kakao SDK v2 (`com.kakao.sdk:v2-user`) 기반

### 3-1. 카카오 개발자 콘솔 Android 플랫폼 설정

```
developers.kakao.com → 내 애플리케이션 → [앱 선택]
  → 플랫폼 → Android → 추가 또는 수정
    → 패키지명: com.waitee.app
    → 키 해시: [아래 방법으로 추출한 값 입력]
    → 마켓 URL: 선택 사항
```

**키 해시 추출 방법 (Play Store 배포 빌드)**

Play Console에서 앱 서명 키 DER 인증서를 다운로드한다.

```
Play Console → 앱 서명 → 앱 서명 키 인증서 → 인증서 다운로드(DER)
  → deployment_cert.der 파일 저장
```

터미널에서 키 해시 추출:

```bash
# 방법 1: DER 파일 사용 (가장 정확)
openssl dgst -sha1 -binary deployment_cert.der | base64

# 방법 2: Play Console SHA-1 hex 값 사용
# Play Console SHA-1 예시: AA:BB:CC:DD:EE:FF:...
echo -n "AA:BB:CC:DD:EE:FF:..." | tr -d ':' | xxd -r -p | base64
```

> ⚠️ **잘못된 방법**: Play Console SHA-1 hex 문자열을 직접 base64 인코딩하면 잘못된 값이 된다.
> ```bash
> # 틀린 방법 — 이렇게 하지 말 것
> echo "AA:BB:CC:DD:..." | base64
> ```

**디버그 빌드용 키 해시** (로컬 개발 테스트 시 필요):
```bash
keytool -exportcert \
  -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android \
  | openssl sha1 -binary | openssl base64
```

카카오 개발자 콘솔에 릴리즈 키 해시와 디버그 키 해시를 **모두** 등록한다.

### 3-2. android/app/build.gradle 설정

```groovy
def kakaoNativeAppKey = "카카오_네이티브_앱_키"

android {
    defaultConfig {
        // 카카오 SDK AndroidManifest의 ${kakaoNativeAppKey} 치환
        manifestPlaceholders = [
            kakaoNativeAppKey: kakaoNativeAppKey
        ]
    }
}

repositories {
    // 카카오 SDK Maven 저장소
    maven { url 'https://devrepo.kakao.com/nexus/content/groups/public/' }
}

dependencies {
    // Kakao SDK v2 (사용자 관리)
    implementation "com.kakao.sdk:v2-user:2.23.0"
}
```

### 3-3. capacitor.config.ts 설정

```typescript
plugins: {
  KakaoLogin: {
    appKey: "카카오_네이티브_앱_키",
  },
}
```

### 3-4. 소스 코드 연결

`src/features/auth/lib/kakao/kakaoSdkAdapter.ts`:
```typescript
import { KakaoLogin } from "@chuseok22/capacitor-kakao-login";

export async function getKakaoSocialId(): Promise<string> {
  const result = await KakaoLogin.login();
  if (!result.socialId || result.socialId.trim().length === 0) {
    throw new Error("카카오 사용자 ID를 가져올 수 없습니다");
  }
  return result.socialId;
}
```

### 3-5. 카카오 로그인 동작 방식 차이

| 환경 | 동작 | 키 해시 검증 |
|------|------|------------|
| 카카오톡 미설치 | 웹뷰(카카오 계정) 로그인 | 없음 |
| 카카오톡 설치 | 카카오톡 앱 → 딥링크 리다이렉트 | **있음** |

카카오톡이 설치된 환경에서는 키 해시 불일치 시 인증 후 앱 복귀 단계에서 오류가 발생한다.

---

## 4. Android 네이티브 코드 설정

### 4-1. MainActivity.java

`@capgo/capacitor-social-login` 플러그인이 scopes(profile, email) 인증 단계에서 Activity 결과를 수신하려면 아래와 같이 수정해야 한다.

`android/app/src/main/java/com/waitee/app/MainActivity.java`:

```java
package com.waitee.app;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.getcapacitor.BridgeActivity;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginHandle;

import ee.forgr.capacitor.social.login.GoogleProvider;
import ee.forgr.capacitor.social.login.ModifiedMainActivityForSocialLoginPlugin;
import ee.forgr.capacitor.social.login.SocialLoginPlugin;

public class MainActivity extends BridgeActivity implements ModifiedMainActivityForSocialLoginPlugin {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode >= GoogleProvider.REQUEST_AUTHORIZE_GOOGLE_MIN
                && requestCode < GoogleProvider.REQUEST_AUTHORIZE_GOOGLE_MAX) {
            PluginHandle pluginHandle = getBridge().getPlugin("SocialLogin");

            if (pluginHandle == null) {
                Log.i("Google Activity Result", "SocialLogin plugin handle is null");
                return;
            }

            Plugin plugin = pluginHandle.getInstance();
            if (!(plugin instanceof SocialLoginPlugin)) {
                Log.i("Google Activity Result", "SocialLogin plugin instance is not SocialLoginPlugin");
                return;
            }

            ((SocialLoginPlugin) plugin).handleGoogleLoginIntent(requestCode, data);
        }
    }

    @Override
    public void IHaveModifiedTheMainActivityForTheUseWithSocialLoginPlugin() {
        // 플러그인 인터페이스 계약용 메서드. 호출되지 않는다.
    }
}
```

> `ModifiedMainActivityForSocialLoginPlugin` 인터페이스 구현 및 `onActivityResult` 오버라이드는 플러그인이 Google scope 인증 결과를 수신하기 위해 필수이다.

---

## 5. ProGuard 설정

릴리즈 빌드는 `minifyEnabled true`로 R8/ProGuard가 활성화된다. 소셜 로그인 관련 클래스가 삭제되지 않도록 `android/app/proguard-rules.pro`에 Keep 규칙을 추가한다.

```proguard
# Firebase / Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Firebase KTX 경고 억제
-dontwarn com.google.firebase.ktx.**
-dontwarn com.google.firebase.installations.ktx.**

# Capacitor 플러그인 (리플렉션 기반 로딩)
-keep class com.getcapacitor.** { *; }
-keep class * extends com.getcapacitor.Plugin { *; }

# Kakao SDK v2
-keep class com.kakao.sdk.** { *; }
```

---

## 6. CI/CD 환경변수 설정

`.github/workflows/react-basic-cicd.yml` 또는 빌드 워크플로우에서 아래 환경변수를 설정한다.

```yaml
env:
  VITE_GOOGLE_IOS_CLIENT_ID: "836964428266-{ios_client_id}.apps.googleusercontent.com"
  VITE_GOOGLE_WEB_CLIENT_ID: "836964428266-{web_client_id}.apps.googleusercontent.com"
  # ↑ iOS와 Web 클라이언트 ID의 프로젝트 번호(836964428266)가 일치해야 한다.
```

**GitHub Actions Secrets 목록 (Android 빌드 관련):**

| Secret | 설명 |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | 업로드 키스토어 (base64 인코딩) |
| `ANDROID_KEYSTORE_PASSWORD` | 키스토어 비밀번호 |
| `GOOGLE_SERVICES_JSON` | Firebase google-services.json 내용 |

---

## 7. 최종 체크리스트

### Google Sign-In

- [ ] GCP Console에 **Android 타입** OAuth 클라이언트가 있다
    - 패키지명: `com.waitee.app`
    - SHA-1: Play Console **앱 서명 키** 인증서 SHA-1 (업로드 키가 아님)
- [ ] GCP Console에 **Web application 타입** OAuth 클라이언트가 있다
- [ ] Android 클라이언트와 Web 클라이언트가 **같은 GCP 프로젝트**에 있다
    - 클라이언트 ID 앞 숫자(프로젝트 번호)가 동일한지 확인
- [ ] `VITE_GOOGLE_WEB_CLIENT_ID`에 Web application 클라이언트 ID 설정
- [ ] `MainActivity.java`에 `ModifiedMainActivityForSocialLoginPlugin` 구현 및 `onActivityResult` 추가
- [ ] `proguard-rules.pro`에 Google Play Services Keep 규칙 존재
- [ ] OAuth 동의 화면 게시 상태 확인 (테스트 중 / 프로덕션)

### Kakao 로그인

- [ ] 카카오 개발자 콘솔에 Android 플랫폼 등록
    - 패키지명: `com.waitee.app`
    - 키 해시: Play Console **앱 서명 키** 기반 keyhash (올바른 변환 방법 사용)
    - 키 해시: 디버그 키스토어 keyhash (개발 테스트용)
- [ ] `android/app/build.gradle`에 `manifestPlaceholders[kakaoNativeAppKey]` 설정
- [ ] `android/app/build.gradle`에 Kakao Maven 저장소 및 SDK 의존성 추가
- [ ] `proguard-rules.pro`에 Kakao SDK Keep 규칙 존재

---

## 8. 오류별 원인 및 해결

### Google Sign-In

#### `GetCredentialCancellationException: activity is cancelled by the user`

| 원인 | 확인 방법 | 해결 |
|------|-----------|------|
| `webClientId`와 Android OAuth 클라이언트가 다른 GCP 프로젝트 | 두 클라이언트 ID 앞 숫자(프로젝트 번호) 비교 | 같은 프로젝트의 Web application 클라이언트 ID 사용 |
| Android OAuth 클라이언트에 업로드 키 SHA-1 등록 (앱 서명 키가 아님) | Play Console에서 앱 서명 키 / 업로드 키 구분 확인 | 앱 서명 키 SHA-1로 재등록 |
| Android OAuth 클라이언트 자체 미등록 | GCP Console OAuth 클라이언트 목록에서 Android 타입 확인 | Android 타입 클라이언트 신규 생성 |
| 패키지명 불일치 | GCP Console Android 클라이언트의 패키지명 확인 | `com.waitee.app`으로 수정 |

#### 디버그 빌드에서는 동작, 릴리즈에서만 실패

- Google Play App Signing 미사용(디버그)과 사용(릴리즈)의 서명 키 차이
- 릴리즈 빌드의 GCP Android 클라이언트 SHA-1이 **앱 서명 키** 기반인지 확인

---

### Kakao 로그인

#### 카카오톡 설치 환경에서 인증 후 앱 복귀 시 오류

| 원인 | 해결 |
|------|------|
| 카카오 개발자 콘솔에 릴리즈 키 해시 미등록 | 앱 서명 키 기반 keyhash 추출 후 등록 |
| 업로드 키 기반 keyhash 등록 (앱 서명 키가 아님) | 앱 서명 키 기반으로 재추출 및 재등록 |
| keyhash를 hex 문자열로 직접 base64 인코딩한 경우 | `xxd -r -p \| base64` 또는 DER 파일로 재추출 |

**릴리즈 키 해시 올바른 추출 명령어:**
```bash
# DER 파일 방법 (권장)
openssl dgst -sha1 -binary deployment_cert.der | base64

# SHA-1 hex 방법
echo -n "SHA1_HEX_콜론_포함" | tr -d ':' | xxd -r -p | base64
```

#### 카카오톡 미설치 환경에서는 동작, 설치 환경에서만 실패

- 키 해시 검증은 카카오톡 앱 로그인 경로에서만 수행됨
- 웹뷰 로그인은 키 해시 검증 없이 동작
- 위 keyhash 재등록 절차 수행

---

## 📎 관련 파일 위치

| 파일 | 역할 |
|------|------|
| `android/app/src/main/java/com/waitee/app/MainActivity.java` | Google 로그인 Activity 결과 처리 |
| `android/app/build.gradle` | Kakao 앱키, Maven 저장소, SDK 의존성 |
| `android/app/proguard-rules.pro` | 릴리즈 빌드 클래스 보호 규칙 |
| `src/features/auth/lib/google/googleSdkAdapter.ts` | Google 로그인 SDK 초기화 및 호출 |
| `src/features/auth/lib/kakao/kakaoSdkAdapter.ts` | Kakao 로그인 SDK 호출 |
| `src/shared/utils/env.ts` | 환경변수 검증 및 export |
| `.github/workflows/react-basic-cicd.yml` | 빌드 환경변수 주입 |
