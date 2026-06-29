//
//  ReceiptListViewModel.swift
//  BOAT
//
//  영수증 목록 화면 상태 관리. 첫 페이지 로드 + 커서 기반 무한 스크롤.
//  탭/정렬/카테고리 변경 시 reload, 마지막 카드 도달 시 loadMore.
//

import SwiftUI

@MainActor
@Observable
final class ReceiptListViewModel {

    private(set) var receipts: [Receipt] = []
    private(set) var totalCount = 0

    /// 첫 페이지 로딩 (전체 화면 인디케이터)
    private(set) var isLoading = false
    /// 다음 페이지 로딩 (하단 푸터 인디케이터)
    private(set) var isLoadingMore = false
    /// 첫 페이지 로드를 한 번이라도 끝냈는지 (empty 판정용)
    private(set) var didLoadOnce = false
    private(set) var errorMessage: String?

    private var nextCursor: String?
    private var hasNext = false

    // 현재 적용된 필터 (loadMore에서 동일 조건 유지)
    private var tab: ReceiptTab = .all
    private var sort: ReceiptSort = .default
    private var filter: ReceiptFilter = .all

    /// reload 세대 토큰 — 필터 변경 시 이전 요청 결과를 무시하기 위함
    private var generation = 0

    private let repository = ReceiptRepository.shared

    /// 탭/정렬/카테고리 변경 또는 첫 진입 시 호출 — 첫 페이지부터 다시 조회
    func reload(tab: ReceiptTab, sort: ReceiptSort, filter: ReceiptFilter) async {
        self.tab = tab
        self.sort = sort
        self.filter = filter

        generation += 1
        let token = generation

        isLoading = true
        isLoadingMore = false
        errorMessage = nil

        do {
            let data = try await repository.fetchReceipts(
                tab: tab, sort: sort, filter: filter, cursor: nil
            )
            guard token == generation else { return } // 더 최신 요청이 들어왔으면 폐기
            receipts = data.receipts
            totalCount = data.pagination.totalCount
            nextCursor = data.pagination.nextCursor
            hasNext = data.pagination.hasNext
        } catch {
            guard token == generation else { return }
            receipts = []
            totalCount = 0
            nextCursor = nil
            hasNext = false
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? String(localized: "error.api.unknown")
        }

        guard token == generation else { return }
        isLoading = false
        didLoadOnce = true
    }

    /// 마지막 근처 카드가 보일 때 호출 — 다음 페이지 추가 로드
    func loadMoreIfNeeded(currentItem item: Receipt) async {
        guard hasNext, !isLoading, !isLoadingMore else { return }
        // 끝에서 3번째 이내가 나타나면 미리 로드
        let thresholdIndex = receipts.index(receipts.endIndex, offsetBy: -3, limitedBy: receipts.startIndex) ?? receipts.startIndex
        guard let itemIndex = receipts.firstIndex(where: { $0.receiptId == item.receiptId }),
              itemIndex >= thresholdIndex else { return }
        await loadMore()
    }

    private func loadMore() async {
        guard hasNext, !isLoading, !isLoadingMore, let cursor = nextCursor else { return }

        let token = generation
        isLoadingMore = true

        do {
            let data = try await repository.fetchReceipts(
                tab: tab, sort: sort, filter: filter, cursor: cursor
            )
            guard token == generation else { return }
            receipts.append(contentsOf: data.receipts)
            totalCount = data.pagination.totalCount
            nextCursor = data.pagination.nextCursor
            hasNext = data.pagination.hasNext
        } catch {
            guard token == generation else { return }
            // 추가 로드 실패는 조용히 멈춤 (다음 스크롤에서 재시도 가능)
            hasNext = false
        }

        guard token == generation else { return }
        isLoadingMore = false
    }
}
