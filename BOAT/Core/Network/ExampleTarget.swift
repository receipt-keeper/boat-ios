//
//  ExampleTarget.swift
//  BOAT
//
//  서버 동작 테스트용 임시 엔드포인트. PM 검증 후 제거 예정.
//

import Alamofire

enum ExampleTarget {
    case serverError
    /// [TEST] 로그인 사용자의 등록된 모든 디바이스로 테스트 푸시 즉시 발송. 알림 레코드 미생성, 수신 설정 미확인.
    /// FCM 연동 확인용 임시 API — PM 검증 후 제거 예정.
    case testPush(title: String, body: String)
}

extension ExampleTarget: TargetType {
    var path: String {
        switch self {
        case .serverError: return "/api/v1/example/server-error"
        case .testPush:    return "/api/v1/example/push"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .serverError: return .get
        case .testPush:    return .post
        }
    }

    var task: RequestTask {
        switch self {
        case let .testPush(title, body):
            return .body(["title": title, "body": body])
        case .serverError:
            return .plain
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .serverError: return false
        case .testPush:    return true
        }
    }
}

/// POST /api/v1/example/push 응답 — 발송 대상/무효 디바이스 수.
struct TestPushData: Decodable {
    let invalidDeviceCount: Int
    let targetedDeviceCount: Int
}
