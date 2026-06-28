//
//  UsageTarget.swift
//  BOAT
//
//  사용 가능 여부 엔드포인트. GET /api/v1/usage
//

import Foundation
import Alamofire

enum UsageTarget {
    case getUsage
}

extension UsageTarget: TargetType {
    var path: String      { "/api/v1/usage" }
    var method: HTTPMethod { .get }
    var task: RequestTask  { .plain }
}
