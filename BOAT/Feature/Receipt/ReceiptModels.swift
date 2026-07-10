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
    // 상세 조회 응답에만 포함 — 로컬 캐시(ReceiptEntity)는 왕복시키지 않으므로 기본값 필요.
    // ⚠️ `let`에 초기값을 주면 Decodable 합성 시 JSON에서 아예 디코딩하지 않고 항상 nil이 된다
    // (Xcode가 "will not be decoded" 경고를 띄운다) — 반드시 `var`여야 실제 값이 반영된다.
    var receiptFiles: [ReceiptFile]? = nil
    let imageUrl: String?
    let warrantyDDay: Int?         // 만료까지 남은 일수 (음수면 만료)
    let serialNumber: String?
    let supportUrl: String?
    let registeredAt: String?      // ISO8601

    var id: String { receiptId }
}

/// 첨부된 영수증 원본 파일. contentPath는 Authorization 토큰을 붙여 조회해야 하는
/// 인증 필요 엔드포인트다 — AuthenticatedImage에서 FileRepository.fetchContent(path:)로 로드.
struct ReceiptFile: Decodable, Hashable {
    let fileId: String
    let contentPath: String
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

// MARK: - 파생 표시값

extension Receipt {

    /// 만료 임박 기준 (이하이면 경고색). D-day 표시는 공용 DDayBadge 컴포넌트가 담당.
    static let expiringThresholdDays = 30

    /// "yyyy-MM-dd" → "yyyy. MM. dd"
    var formattedExpiresOn: String {
        guard let expiresOn else { return "-" }
        let parts = expiresOn.split(separator: "-")
        guard parts.count == 3 else { return expiresOn }
        return parts.joined(separator: ". ")
    }

    /// imageUrl이 없을 때 폴백할 카테고리 기본 이미지 결정에 사용
    var deviceCategory: DeviceCategory? {
        DeviceCategory.from(serverValue: category)
    }

    /// category + subCategory에 대응하는 로컬 이미지 에셋 이름.
    /// 소분류(대표 기기명) 전용 이미지 → 대분류 기본 → 공통(img_misc) 순으로 폴백.
    var deviceImageName: String {
        DeviceImage.assetName(category: category, subCategory: subCategory)
    }
}
