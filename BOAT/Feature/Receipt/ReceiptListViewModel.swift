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
    private var q: String?

    /// reload 세대 토큰 — 필터 변경 시 이전 요청 결과를 무시하기 위함
    private var generation = 0

    private let repository = ReceiptRepository.shared

    /// 탭/정렬/카테고리 변경 또는 첫 진입 시 호출 — 첫 페이지부터 다시 조회.
    /// q: 검색어(제품명/메모) — 검색 화면에서만 사용, 목록 탭에서는 nil.
    /// silent: 다른 화면의 변경(등록/수정/삭제) 동기화용 배경 재조회. true면 로딩 스피너를 띄우지
    ///   않고 기존 목록을 유지한 채 새 데이터로 교체한다(전체 리스트가 잠깐 사라졌다 나타나는 깜빡임 방지).
    func reload(tab: ReceiptTab, sort: ReceiptSort, filter: ReceiptFilter, q: String? = nil, silent: Bool = false) async {
        self.tab = tab
        self.sort = sort
        self.filter = filter
        self.q = q

        generation += 1
        let token = generation

        if !silent { isLoading = true }
        isLoadingMore = false
        errorMessage = nil

        do {
            let data = try await repository.fetchReceipts(
                tab: tab, sort: sort, filter: filter, q: q, cursor: nil
            )
            guard token == generation else { return } // 더 최신 요청이 들어왔으면 폐기
            receipts = data.receipts
            // 대분류 필터는 클라이언트에서 걸러내므로(ReceiptRepository 참고), 서버 totalCount는
            // 필터 무관 전체 건수라 그대로 쓸 수 없다 — 전체 탭만 서버 값을, 나머지는 로드된
            // 필터링 결과 개수를 카운트로 노출한다(스크롤할수록 정확해짐).
            totalCount = filter == .all ? data.pagination.totalCount : receipts.count
            nextCursor = data.pagination.nextCursor
            hasNext = data.pagination.hasNext
        } catch {
            guard token == generation else { return }
            // 배경(silent) 재조회 실패 시엔 현재 보이는 목록을 유지한다(깜빡임/의도치 않은 비움 방지).
            if !silent {
                receipts = []
                totalCount = 0
                nextCursor = nil
                hasNext = false
                errorMessage = (error as? LocalizedError)?.errorDescription
                    ?? String(localized: "error.api.unknown")
            }
        }

        guard token == generation else { return }
        isLoading = false
        didLoadOnce = true
    }

    /// 영수증 삭제 — DELETE API 성공 시 로컬 캐시 + 화면 목록에서 함께 제거.
    /// 실패 시 목록은 그대로 유지하고 false를 반환 (호출부에서 에러 토스트 처리).
    @discardableResult
    func deleteReceipt(id: String) async -> Bool {
        do {
            try await repository.deleteReceipt(id: id)
        } catch {
            return false
        }
        removeFromList(id: id)
        return true
    }

    /// 목록 배열에서만 제거 (서버 삭제는 이미 완료된 경우 — 상세 화면 삭제 후 동기화용).
    func removeFromList(id: String) {
        let before = receipts.count
        receipts.removeAll { $0.receiptId == id }
        if receipts.count != before {
            totalCount = max(0, totalCount - 1)
        }
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
                tab: tab, sort: sort, filter: filter, q: q, cursor: cursor
            )
            guard token == generation else { return }
            receipts.append(contentsOf: data.receipts)
            totalCount = filter == .all ? data.pagination.totalCount : receipts.count
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
