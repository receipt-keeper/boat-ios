# BOAT iOS

> 영수증 스캔 한 번으로 가전제품 AS 기간을 자동 관리하는 앱

[![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-007AFF?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Xcode](https://img.shields.io/badge/Xcode-16-147EFB?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![iOS](https://img.shields.io/badge/iOS-16.0+-000000?logo=apple)](https://developer.apple.com/ios/)

---

## 📦 Tech Stack

### Language & UI
| 항목 | 내용 |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Minimum Deployment | iOS 16.0 |
| Xcode | 16 |

### 외부 라이브러리 (SPM)
| 라이브러리 | 버전 | 용도 |
|---|---|---|
| [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk) | 12.14.0 | Auth, Crashlytics |
| [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) | 9.1.0 | 구글 소셜 로그인 |
| [Alamofire](https://github.com/Alamofire/Alamofire) | 5.12.0 | HTTP 네트워크 |
| [Kingfisher](https://github.com/onevcat/Kingfisher) | 8.9.0 | 이미지 로딩 / 캐싱 |

### 네이티브 프레임워크
| 프레임워크 | 용도 |
|---|---|
| Vision | 영수증 OCR 텍스트 인식 |
| AuthenticationServices | Apple Sign-In |
| CryptoKit | Apple Sign-In nonce SHA-256 해싱 |
| PhotosUI | 갤러리 이미지 선택 |
| UserNotifications | AS 만료 알림 |
| Security | Keychain 보안 저장 |

---

## 🏗 Architecture

### MVI (Model - View - Intent)

```
User Action
    │
    ▼
Intent (sealed enum)          ← 사용자 의도를 타입 안전하게 캡슐화
    │
    ▼
ViewModel (@Observable)       ← 비즈니스 로직, 상태 전이 담당
    │
    ▼
State (enum)                  ← 화면 상태를 idle / loading / success / error 로 분기
    │
    ▼
View (SwiftUI)                ← 상태를 그대로 렌더링, 부수효과 없음
```

안드로이드 팀과 동일한 MVI 패턴을 사용해 플랫폼 간 구조적 일관성을 유지합니다.

**예시 — 인증 흐름**

```swift
// Intent
enum AuthIntent {
    case signInWithGoogle
    case signInWithApple(Result<ASAuthorization, Error>)
    case signOut
}

// State
enum AuthState: Equatable {
    case idle
    case loading
    case authenticated(SocialUserInfo)
    case unauthenticated
    case error(String)
}

// ViewModel
@Observable class AuthViewModel {
    var state: AuthState = .idle
    func dispatch(_ intent: AuthIntent) { ... }
}
```

---

## 🔍 OCR 파이프라인

```
UIImage
  │
  ▼
OCRService (actor)            ← Swift actor로 스레드 안전 보장
  │  VNRecognizeTextRequest
  │  언어: ["ko-KR", "en-US"]
  │  정확도: .accurate
  ▼
[String]  (줄 단위, 위→아래 정렬)
  │
  ▼
ReceiptParser.parse(lines:)   ← 정규식 기반 필드 추출
  │
  ├─ 구매일   : 5가지 날짜 패턴 (yyyy.MM.dd / yyyy-MM-dd / 한국어 년월일 등)
  ├─ 보증기간  : "보증기간 / warranty" 키워드 → N년 × 12 or N개월 (범위: 1–60)
  ├─ 가격     : 결제금액 우선, 폴백 → 최댓값 "숫자원" 패턴
  ├─ 시리얼   : S/N, 시리얼, 일련번호 키워드
  ├─ 브랜드   : 34개 브랜드 사전 + 제조사 키워드
  ├─ 제품명   : 품명/모델명 키워드 → 브랜드 포함 줄 → 노이즈 필터 (최대 30자)
  └─ 대분류   : DeviceCategory 키워드 매칭 (주방/세탁/리빙/IT/기타)
  │
  ▼
ParsedReceipt                 ← PRD 기본값 적용 (구매일 없음→오늘, 보증기간 없음→12개월)
```

---

## 🌐 네트워크 레이어

Retrofit 스타일의 `TargetType` 프로토콜로 엔드포인트를 선언적으로 정의합니다.

```swift
// 엔드포인트 선언
enum AuthTarget: TargetType {
    case login(idToken: String)

    var path: String { "/api/v1/auth/login" }
    var method: HTTPMethod { .post }
    var task: RequestTask { .body(["idToken": idToken]) }
}

// 호출 — async/await, 제네릭 디코딩 자동 처리
let user: UserDTO = try await APIClient.shared.request(AuthTarget.login(idToken: token))
```

**응답 Envelope 구조**

```json
{
  "status": 200,
  "message": "success",
  "data": { ... }
}
```

`APIClient`가 envelope를 벗겨 `data`만 반환하며, 4xx/5xx 시 서버 메시지를 `APIError.server`로 래핑합니다.

---

## 📁 프로젝트 구조

```
BOAT/
├── BOATApp.swift
│
├── Core/
│   ├── Network/          # APIClient, TargetType, APIError, BaseURL
│   ├── OCR/              # OCRService, ReceiptParser, ParsedReceipt, OCRError
│   ├── DesignSystem/     # Color+Foundation, Spacing+Foundation
│   ├── Extensions/       # UIImage+Utils, String+Utils
│   ├── Permission/       # PermissionManager
│   ├── Security/         # KeychainManager
│   └── Logger/           # CrashReporter (Firebase Crashlytics)
│
├── Feature/
│   └── Auth/
│       ├── Model/        # SocialUserInfo
│       ├── State/        # AuthState
│       ├── Intent/       # AuthIntent
│       ├── ViewModel/    # AuthViewModel
│       ├── View/         # LoginView
│       └── Helper/       # AppleSignInHelper
│
└── Resources/
    ├── Fonts/            # 커스텀 폰트 (lowercase_underscore 네이밍)
    └── Localizable.xcstrings   # 문자열 리소스 (String Catalog)
```

> **Xcode 16 `PBXFileSystemSynchronizedRootGroup`** 적용 — `BOAT/` 하위에 `.swift` 파일을 추가하면 `project.pbxproj` 수정 없이 자동으로 컴파일 대상에 포함됩니다.

---

## 🔐 인증 흐름

```
Google Sign-In          Apple Sign-In (SignInWithAppleButton)
      │                          │
      │                  prepareRequest()  ← nonce 생성 + SHA-256 해싱
      │                          │
      ▼                          ▼
 idToken                  process(result:)  ← email/name 추출 (최초 1회)
      │                          │
      └──────────┬───────────────┘
                 ▼
         Firebase Auth.signIn(with: credential)
                 │
                 ▼
           AuthState.authenticated(SocialUserInfo)
```

Apple의 이메일/이름은 **최초 로그인 시에만** 제공되므로, 인증 즉시 백엔드에 전송합니다.

---

## 🗓 마일스톤

| 버전 | 내용 | 목표일 |
|---|---|---|
| v0.1.0 | 프로젝트 세팅 + 로그인/인증 + 홈 화면 | 2026-06-28 |
| v0.2.0 | OCR(영수증 스캔) 화면 + API 연동 + 영수증 등록 | 2026-07-05 |
| v0.3.0 | 영수증 관리 + 검색 / 필터 | 2026-07-09 |
| v0.4.0 | AS 알림 + 추천 화면 | 2026-07-12 |
| v1.0.0 | 광고 등록 + MVP 배포 | 2026-07-13 |

---

## 👥 Git 컨벤션

### 브랜치
```
feature/{feature-name}
fix/{issue-name}
design/{screen-name}
```

### 커밋 타입
| 타입 | 설명 |
|---|---|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `design` | UI/UX 변경 |
| `refactor` | 리팩토링 |
| `chore` | 빌드, 설정, 기타 |

### 스코프
`feat(ios): ...` — 플랫폼 스코프는 `ios` / `android` / `common` 사용 (`aos` 사용 금지)

### Merge 전략
`Squash Merge` — PR 단위로 커밋을 하나로 합칩니다.

---

## ⚙️ 개발 환경 설정

```bash
# 1. 레포 클론
git clone https://github.com/receipt-keeper/boat-ios.git

# 2. Xcode 16에서 BOAT.xcodeproj 열기
open BOAT.xcodeproj

# 3. Xcode → File → Packages → Resolve Package Versions
#    (SPM 패키지 자동 다운로드)

# 4. GoogleService-Info.plist 팀 공유 채널에서 받아 BOAT/ 경로에 추가
```

> `GoogleService-Info.plist`는 보안상 Git에 포함되지 않습니다. 팀 내부 채널을 통해 공유받으세요.
