//
//  CreditTarget.swift
//  BOAT
//
//  크레딧(무료 분석 토큰) 엔드포인트. GET /api/v1/credits
//

import Foundation
import Alamofire

enum CreditTarget {
    case getCredits
}

extension CreditTarget: TargetType {
    var path: String   { "/api/v1/credits" }
    var method: HTTPMethod { .get }
    var task: RequestTask  { .plain }
}
