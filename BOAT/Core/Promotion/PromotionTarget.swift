//
//  PromotionTarget.swift
//  BOAT
//
//  프로모션(월간 크레딧 충전) 엔드포인트.
//  - GET  /api/v1/promotions?featureKey=&context=            — 충전 프로모션 조회
//  - POST /api/v1/promotions/{promotionId}/redemptions       — 크레딧 수령
//

import Foundation
import Alamofire

enum PromotionTarget {
    /// GET /api/v1/promotions?featureKey=ocr&context=recharge
    case list(featureKey: String, context: String)
    /// POST /api/v1/promotions/{promotionId}/redemptions
    /// Idempotency-Key 헤더로 중복 수령을 방지한다.
    case redeem(promotionId: String, idempotencyKey: String)
}

extension PromotionTarget: TargetType {
    var path: String {
        switch self {
        case .list:
            return "/api/v1/promotions"
        case let .redeem(promotionId, _):
            return "/api/v1/promotions/\(promotionId)/redemptions"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list:   return .get
        case .redeem: return .post
        }
    }

    var task: RequestTask {
        switch self {
        case let .list(featureKey, context):
            return .query(["featureKey": featureKey, "context": context])
        case .redeem:
            return .plain
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .list:
            return ["Content-Type": "application/json"]
        case let .redeem(_, idempotencyKey):
            return ["Content-Type": "application/json", "Idempotency-Key": idempotencyKey]
        }
    }
}
