//
//  PromotionRepository.swift
//  BOAT
//
//  월간 크레딧 충전 프로모션 조회/수령. (구 ExampleTarget.ocrTestCredits 대체)
//  연동 순서: GET /usage 로 canAnalyze 확인 → false면 GET /promotions 로 조회 →
//  state=redeemable 이면 POST /redemptions 로 수령 → balance.remainingCount 반영.
//

import Foundation

// MARK: - Model

/// 현재 사용자 기준 프로모션 상태. 앱은 이 값으로 충전 버튼 노출/처리를 결정한다.
enum PromotionState: String, Decodable {
    case redeemable        // 수령 가능 → 충전 버튼 노출
    case alreadyRedeemed   // 이번 달 이미 수령 (수령 API 성공 응답의 state도 이 값)
    case unavailable       // 노출할 프로모션 없음
    case expired           // 만료된 혜택
    case exhausted         // 수량 소진
    case unknown           // 서버가 새 값을 추가한 경우 방어

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PromotionState(rawValue: raw) ?? .unknown
    }
}

/// 프로모션으로 받을 혜택 (기능 + 지급 수량)
struct PromotionBenefit: Decodable {
    let featureKey: String
    let amount: Int
}

/// 프로모션 전체 수령 수량 상태
struct PromotionRedemption: Decodable {
    let remainingRedemptions: Int?
}

/// 수령 API 응답에만 채워지는 현재 사용자 크레딧 잔액. (조회 API에서는 null)
struct PromotionBalance: Decodable {
    let totalGrantedCount: Int
    let remainingCount: Int
}

/// 프로모션 배너 이미지 (없으면 nil)
struct PromotionBannerImage: Decodable {
    let imageUrl: String
}

/// GET /promotions, POST /redemptions 공통 data 페이로드.
struct Promotion: Decodable {
    let state: PromotionState
    let promotionId: String?
    let benefit: PromotionBenefit?
    let redemption: PromotionRedemption?
    let balance: PromotionBalance?
    let bannerImage: PromotionBannerImage?
}

// MARK: - Repository

@MainActor
final class PromotionRepository {
    static let shared = PromotionRepository()
    private init() {}

    /// GET /api/v1/promotions?featureKey=ocr&context=recharge — 월간 OCR 충전 프로모션 조회.
    func fetchOcrRecharge() async throws -> Promotion {
        try await APIClient.shared.request(
            PromotionTarget.list(featureKey: "ocr", context: "recharge")
        )
    }

    /// POST /api/v1/promotions/{promotionId}/redemptions — 월간 OCR 크레딧 수령.
    /// - Parameter idempotencyKey: 중복 수령 방지 키. 같은 논리 요청의 재시도에는 같은 값을 재사용한다.
    func redeem(promotionId: String, idempotencyKey: String = UUID().uuidString) async throws -> Promotion {
        try await APIClient.shared.request(
            PromotionTarget.redeem(promotionId: promotionId, idempotencyKey: idempotencyKey)
        )
    }
}
