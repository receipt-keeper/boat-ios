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
}

extension ExampleTarget: TargetType {
    var path: String {
        switch self {
        case .serverError:    return "/api/v1/example/server-error"
        case .ocrTestCredits: return "/api/v1/example/ocr-test-credits"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .serverError:    return .get
        case .ocrTestCredits: return .post
        }
    }

    var task: RequestTask { .plain }

    var requiresAuth: Bool {
        switch self {
        case .serverError:    return false
        case .ocrTestCredits: return true
        }
    }
}
