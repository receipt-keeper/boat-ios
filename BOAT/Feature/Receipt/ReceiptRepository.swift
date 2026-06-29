//
//  ReceiptRepository.swift
//  BOAT
//
//  영수증 목록 조회. GET /api/v1/receipts — 커서 기반 페이지네이션.
//

import Foundation

@MainActor
final class ReceiptRepository {
    static let shared = ReceiptRepository()
    private init() {}

    /// 페이지당 최대 조회 수 (API maximum = 50)
    static let pageSize = 20

    /// GET /api/v1/receipts
    /// - Parameters:
    ///   - tab: 보증 상태 필터 (status)
    ///   - sort: 정렬 기준
    ///   - filter: 카테고리 필터
    ///   - q: 검색어 (없으면 nil)
    ///   - cursor: 다음 페이지 커서 (첫 조회는 nil)
    func fetchReceipts(
        tab: ReceiptTab,
        sort: ReceiptSort,
        filter: ReceiptFilter,
        q: String? = nil,
        cursor: String? = nil
    ) async throws -> ReceiptListData {
        try await APIClient.shared.request(
            ReceiptTarget.list(
                status: tab.apiStatus,
                sort: sort.apiSort,
                limit: Self.pageSize,
                cursor: cursor,
                category: filter.apiCategory,
                q: q
            )
        )
    }
}
