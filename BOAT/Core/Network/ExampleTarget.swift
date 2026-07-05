//
//  ExampleTarget.swift
//  BOAT
//
//  서버 동작 테스트용 임시 엔드포인트. PM 검증 후 제거 예정.
//

import Alamofire

enum ExampleTarget {
    case serverError
    /// [TEST] OCR 크레딧 5회 임시 지급. 정식 충전/이벤트 지급 API가 나오면 이 case는 제거하고 교체할 것.
    /// TODO: 정식 API로 교체 필요 — example 모듈의 테스트 보조 API(임시)
    case ocrTestCredits
    /// [TEST] 로그인 사용자의 등록된 모든 디바이스로 테스트 푸시 즉시 발송. 알림 레코드 미생성, 수신 설정 미확인.
    /// FCM 연동 확인용 임시 API — PM 검증 후 제거 예정.
    case testPush(title: String, body: String)
}

extension ExampleTarget: TargetType {
    var path: String {
        switch self {
        case .serverError:    return "/api/v1/example/server-error"
        case .ocrTestCredits: return "/api/v1/example/ocr-test-credits"
        case .testPush:       return "/api/v1/example/push"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .serverError:    return .get
        case .ocrTestCredits: return .post
        case .testPush:       return .post
        }
    }

    var task: RequestTask {
        switch self {
        case let .testPush(title, body):
            return .body(["title": title, "body": body])
        case .serverError, .ocrTestCredits:
            return .plain
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .serverError:    return false
        case .ocrTestCredits: return true
        case .testPush:       return true
        }
    }
}

/// POST /api/v1/example/push 응답 — 발송 대상/무효 디바이스 수.
struct TestPushData: Decodable {
    let invalidDeviceCount: Int
    let targetedDeviceCount: Int
}
