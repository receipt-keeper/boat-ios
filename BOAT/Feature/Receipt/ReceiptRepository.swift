//
//  ReceiptRepository.swift
//  BOAT
//
//  영수증 조회/등록/삭제.
//  - GET    /api/v1/receipts             — 커서 기반 페이지네이션. 첫 페이지는 로컬 캐시에 동기화하고,
//                                          네트워크 실패 시 로컬 캐시로 폴백(오프라인 조회).
//  - POST   /api/v1/receipts             — 파일 업로드 → fileId 수집 → 영수증 생성 → 로컬 캐시 저장.
//  - DELETE /api/v1/receipts/{receiptId} — 영수증 삭제 → 로컬 캐시에서도 제거.
//

import UIKit

@MainActor
final class ReceiptRepository {
    static let shared = ReceiptRepository()
    private init() {}

    /// 페이지당 최대 조회 수 (API maximum = 50)
    static let pageSize = 20

    private let local = LocalReceiptStore.shared

    /// GET /api/v1/receipts
    /// 성공 시 첫 페이지를 로컬 캐시에 동기화. 네트워크 실패 시 로컬 캐시로 폴백.
    func fetchReceipts(
        tab: ReceiptTab,
        sort: ReceiptSort,
        filter: ReceiptFilter,
        q: String? = nil,
        cursor: String? = nil
    ) async throws -> ReceiptListData {
        do {
            let data: ReceiptListData = try await APIClient.shared.request(
                ReceiptTarget.list(
                    status: tab.apiStatus,
                    sort: sort.apiSort,
                    limit: Self.pageSize,
                    cursor: cursor,
                    category: filter.apiCategory,
                    q: q
                )
            )
            // 첫 페이지만 로컬 캐시 동기화 (페이지네이션 중간 결과는 캐시 오염 방지 위해 제외)
            if cursor == nil {
                local.upsertAll(data.receipts)
            }
            return data
        } catch {
            // 네트워크/서버 실패 → 로컬 캐시 폴백. 캐시도 비어있으면 원래 에러를 던진다.
            guard cursor == nil, !local.isEmpty else { throw error }
            let cached = local.query(
                status: tab.apiStatus,
                sort: sort.apiSort,
                category: filter.apiCategory,
                q: q
            )
            guard !cached.isEmpty else { throw error }
            return ReceiptListData(
                receipts: cached,
                totalCount: cached.count,
                pagination: ReceiptPagination(
                    hasNext: false,
                    limit: Self.pageSize,
                    nextCursor: nil,
                    totalCount: cached.count
                )
            )
        }
    }

    /// 영수증 등록: 이미지 업로드 → fileId 수집 → POST /api/v1/receipts → 로컬 캐시 저장.
    /// - Parameters:
    ///   - images: 등록할 영수증 이미지 (없으면 업로드 생략)
    ///   - fields: 사용자 입력/OCR 수정값 (item_name 등 최종 바디 필드)
    /// - Returns: 서버가 생성한 영수증(만료일·D-day 등 계산 포함)
    func createReceipt(images: [UIImage], fields: ReceiptCreateFields) async throws -> Receipt {
        // 1) 파일 업로드 → fileId 배열
        var fileIds: [String] = []
        if !images.isEmpty {
            fileIds = try await FileRepository.shared.uploadImages(images).map(\.fileId)
        }

        // 2) 영수증 생성 요청 바디 구성
        let body = fields.requestBody(fileIds: fileIds)
        let receipt: Receipt = try await APIClient.shared.request(ReceiptTarget.create(body: body))

        // 3) 로컬 캐시 저장 (오프라인 조회용)
        local.upsert(receipt)
        return receipt
    }

    /// DELETE /api/v1/receipts/{receiptId} — 서버 삭제 성공 시에만 로컬 캐시에서도 제거.
    func deleteReceipt(id: String) async throws {
        try await APIClient.shared.requestVoid(ReceiptTarget.delete(receiptId: id))
        local.delete(id: id)
    }

    /// GET /api/v1/receipts/{receiptId} — 상세 조회.
    /// 성공 시 로컬 캐시 갱신. 네트워크 실패 시 로컬 캐시로 폴백(오프라인 조회).
    func fetchReceiptDetail(id: String) async throws -> Receipt {
        do {
            let receipt: Receipt = try await APIClient.shared.request(ReceiptTarget.detail(receiptId: id))
            local.upsert(receipt)
            return receipt
        } catch {
            if let cached = local.receipt(id: id) { return cached }
            throw error
        }
    }
}

// MARK: - 등록 요청 필드

/// 영수증 등록 시 사용자가 확정한 값. receipt_file_ids는 업로드 후 주입되므로 제외.
struct ReceiptCreateFields {
    var itemName: String
    var brandName: String?
    var paymentLocation: String?
    var paymentDate: String?          // "yyyy-MM-dd"
    var totalAmount: Int?
    var periodMonths: Int?
    var category: String?
    var subCategory: String?
    var memo: String?
    var requiresPhysicalReceipt: Bool

    /// 서버 스펙(snake_case) 바디로 직렬화. nil/빈 값은 전송하지 않는다.
    func requestBody(fileIds: [String]) -> [String: Any] {
        var body: [String: Any] = [
            "item_name": itemName,
            "requires_physical_receipt": requiresPhysicalReceipt,
            "receipt_file_ids": fileIds
        ]
        if let brandName, !brandName.isEmpty             { body["brand_name"] = brandName }
        if let paymentLocation, !paymentLocation.isEmpty { body["payment_location"] = paymentLocation }
        if let paymentDate, !paymentDate.isEmpty         { body["payment_date"] = paymentDate }
        if let totalAmount                               { body["total_amount"] = totalAmount }
        if let periodMonths                              { body["period_months"] = periodMonths }
        if let category, !category.isEmpty               { body["category"] = category }
        if let subCategory, !subCategory.isEmpty         { body["sub_category"] = subCategory }
        if let memo, !memo.isEmpty                       { body["memo"] = memo }
        return body
    }
}
