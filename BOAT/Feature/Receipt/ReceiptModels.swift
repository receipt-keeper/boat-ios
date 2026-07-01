//
//  ReceiptModels.swift
//  BOAT
//
//  영수증 목록 조회(GET /api/v1/receipts) 응답 모델 + 페이지네이션.
//  Android ReceiptListResponse 대응.
//

import SwiftUI

// MARK: - 단일 영수증

struct Receipt: Decodable, Identifiable, Hashable {
    let receiptId: String
    let itemName: String
    let brandName: String?
    let paymentLocation: String?
    let paymentDate: String?       // "yyyy-MM-dd"
    let totalAmount: Int?
    let periodMonths: Int?
    let expiresOn: String?         // "yyyy-MM-dd" — AS 만료일
    let category: String?          // DeviceCategory rawValue
    let subCategory: String?       // 세부 기기명 (예: 냉장고)
    let memo: String?
    let requiresPhysicalReceipt: Bool?
    let receiptFileIds: [String]?
    let imageUrl: String?
    let warrantyDDay: Int?         // 만료까지 남은 일수 (음수면 만료)
    let serialNumber: String?
    let supportUrl: String?
    let registeredAt: String?      // ISO8601

    var id: String { receiptId }
}

// MARK: - 목록 응답 + 페이지네이션

struct ReceiptListData: Decodable {
    let receipts: [Receipt]
    let totalCount: Int
    let pagination: ReceiptPagination
}

struct ReceiptPagination: Decodable {
    let hasNext: Bool
    let limit: Int
    let nextCursor: String?
    let totalCount: Int
}

// MARK: - D-day 배지 상태 (warrantyDDay 기준)

extension Receipt {

    /// 만료 임박 기준 (이하이면 경고색). 서버 status=expiring 정의와 일치시킬 것.
    static let expiringThresholdDays = 30

    enum WarrantyBadge {
        case safe(dDay: Int)       // 여유 — 파란 배지 "D-N"
        case expiring(dDay: Int)   // 임박 — 빨간 배지 "D-N"
        case expired               // 만료 — 회색 배지 "만료"
    }

    var warrantyBadge: WarrantyBadge {
        let dDay = warrantyDDay ?? 0
        if dDay < 0 { return .expired }
        if dDay <= Self.expiringThresholdDays { return .expiring(dDay: dDay) }
        return .safe(dDay: dDay)
    }

    /// "yyyy-MM-dd" → "yyyy. MM. dd"
    var formattedExpiresOn: String {
        guard let expiresOn else { return "-" }
        let parts = expiresOn.split(separator: "-")
        guard parts.count == 3 else { return expiresOn }
        return parts.joined(separator: ". ")
    }

    /// imageUrl이 없을 때 폴백할 카테고리 기본 이미지 결정에 사용
    var deviceCategory: DeviceCategory? {
        guard let category else { return nil }
        return DeviceCategory(rawValue: category)
    }
}
