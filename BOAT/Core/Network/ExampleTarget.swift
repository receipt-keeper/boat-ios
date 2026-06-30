//
//  ExampleTarget.swift
//  BOAT
//
//  서버 동작 테스트용 임시 엔드포인트. PM 검증 후 제거 예정.
//

import Alamofire

enum ExampleTarget {
    case serverError
}

extension ExampleTarget: TargetType {
    var path: String { "/api/v1/example/server-error" }
    var method: HTTPMethod { .get }
    var task: RequestTask { .plain }
    var requiresAuth: Bool { false }
}
