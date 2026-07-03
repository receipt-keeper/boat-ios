//
//  ReceiptListView.swift
//  BOAT
//
//  목록 탭 — 헤더 + 보증상태 inner tab + 카테고리 필터 칩 + 카운트/정렬 + 리스트(placeholder).
//  Android ReceiptListScreen 대응.
//

import SwiftUI
import Kingfisher

// 보증 상태 inner tab
enum ReceiptTab: CaseIterable {
    case all, expiring, expired
    var title: LocalizedStringKey {
        switch self {
        case .all:      return "receipt.tab.all"
        case .expiring: return "receipt.tab.expiring"
        case .expired:  return "receipt.tab.expired"
        }
    }
}

// 카테고리 필터
enum ReceiptFilter: CaseIterable {
    case all, it, laundry, kitchen, living, other
    var label: LocalizedStringKey {
        switch self {
        case .all:     return "receipt.filter.all"
        case .it:      return "receipt.filter.it"
        case .laundry: return "receipt.filter.laundry"
        case .kitchen: return "receipt.filter.kitchen"
        case .living:  return "receipt.filter.living"
        case .other:   return "receipt.filter.other"
        }
    }
}

// 정렬
enum ReceiptSort: CaseIterable {
    case `default`, expiring, recent, purchase
    var label: LocalizedStringKey {
        switch self {
        case .default:  return "receipt.sort.default"
        case .expiring: return "receipt.sort.expiring"
        case .recent:   return "receipt.sort.recent"
        case .purchase: return "receipt.sort.purchase"
        }
    }
}

struct ReceiptListView: View {

    @Binding var selectedTab: ReceiptTab
    @Binding var selectedSort: ReceiptSort
    var onSearch: () -> Void = {}
    var onNotification: () -> Void = {}
    @State private var selectedFilter: ReceiptFilter = .all
    @State private var sortExpanded = false
    @State private var menuReceiptId: String?
    @State private var viewModel = ReceiptListViewModel()
    @State private var toast = BoatToastState()

    var body: some View {
        VStack(spacing: 0) {
            // 헤더 + inner tab (흰 배경)
            VStack(spacing: 0) {
                BoatHeader(
                    title: "tab.list",
                    onSearch: onSearch,
                    onNotification: onNotification
                )
                innerTabRow
            }
            .background(Color.colorWhite)

            // 카테고리 필터 칩 (가로 스크롤)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing8) {
                    ForEach(ReceiptFilter.allCases, id: \.self) { filter in
                        BoatFilterChip(
                            label: filter.label,
                            selected: filter == selectedFilter,
                            onTap: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal, .spacing20)
                .padding(.vertical, .spacing12)
            }

            // 카운트 + 정렬
            countSortRow

            // 리스트 영역
            listContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.gray50)
        .task { await viewModel.reload(tab: selectedTab, sort: selectedSort, filter: selectedFilter) }
        .onChange(of: selectedTab) { _, _ in reload() }
        .onChange(of: selectedSort) { _, _ in reload() }
        .onChange(of: selectedFilter) { _, _ in reload() }
        // 정렬 드롭다운 — 버튼 위치 기준으로 배치
        .overlayPreferenceValue(SortAnchorKey.self) { anchor in
            if sortExpanded, let anchor {
                GeometryReader { proxy in
                    let rect = proxy[anchor]
                    ZStack(alignment: .topLeading) {
                        // 바깥 탭 시 닫힘 (딤 없음)
                        Color.black.opacity(0.0001)
                            .ignoresSafeArea()
                            .onTapGesture { sortExpanded = false }
                        sortDropdown
                            .frame(width: 176)
                            .offset(x: rect.maxX - 176, y: rect.maxY + 4)
                    }
                }
            }
        }
        // 케밥 → 삭제 메뉴 (선택 카드만 떠오르고 나머지는 딤)
        .overlayPreferenceValue(CardAnchorKey.self) { anchors in
            if let id = menuReceiptId,
               let receipt = viewModel.receipts.first(where: { $0.receiptId == id }),
               let anchor = anchors[id] {
                GeometryReader { proxy in
                    let rect = proxy[anchor]
                    ZStack(alignment: .topLeading) {
                        Color.systemDim
                            .ignoresSafeArea()
                            .onTapGesture { menuReceiptId = nil }

                        // 선택된 카드 복제본 — 딤 위로 떠오름
                        ReceiptCard(receipt: receipt) { menuReceiptId = nil }
                            .frame(width: rect.width, height: rect.height)
                            .offset(x: rect.minX, y: rect.minY)

                        // 삭제 메뉴 — 카드 우상단 위로
                        deleteMenu(id: id)
                            .frame(width: 240)
                            .offset(x: rect.maxX - 240, y: max(0, rect.minY - 64))
                    }
                }
            }
        }
        .boatToastHost(toast)
    }

    // MARK: - 삭제 메뉴

    private func deleteMenu(id: String) -> some View {
        Button {
            menuReceiptId = nil
            Task { await deleteReceipt(id: id) }
        } label: {
            Text("receipt.menu.delete")
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color.systemError)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, .spacing24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
    }

    // MARK: - 정렬 드롭다운 (커스텀)

    private var sortDropdown: some View {
        VStack(spacing: 0) {
            ForEach(ReceiptSort.allCases, id: \.self) { sort in
                Button {
                    selectedSort = sort  // onChange(selectedSort) → reload
                    sortExpanded = false
                } label: {
                    Text(sort.label)
                        .font(.pretendard(sort == selectedSort ? .bold : .regular, size: 16))
                        .foregroundStyle(sort == selectedSort ? Color.gray900 : Color.gray500)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, .spacing16)
                        .padding(.vertical, .spacing12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
    }

    // MARK: - Inner Tab

    private var innerTabRow: some View {
        HStack(spacing: 0) {
            ForEach(ReceiptTab.allCases, id: \.self) { tab in
                let isSelected = tab == selectedTab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 0) {
                        Text(tab.title)
                            .font(.pretendard(isSelected ? .bold : .medium, size: 15))
                            .foregroundStyle(isSelected ? Color.gray900 : Color.gray500)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        Rectangle()
                            .fill(isSelected ? Color.gray900 : Color.gray200)
                            .frame(height: isSelected ? 2 : 1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Count + Sort

    private var countSortRow: some View {
        HStack {
            // 전체 | N
            HStack(spacing: .spacing8) {
                Text("receipt.filter.all")
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray600)
                Text("|")
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray300)
                Text("\(viewModel.totalCount)")
                    .font(.pretendard(.bold, size: 14))
                    .foregroundStyle(Color.brandPrimary)
            }

            Spacer()

            // 정렬 버튼 (탭 → 커스텀 드롭다운)
            Button {
                sortExpanded.toggle()
            } label: {
                HStack(spacing: .spacing4) {
                    Text(selectedSort.label)
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color.gray600)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.gray600)
                }
            }
            .buttonStyle(.plain)
            .anchorPreference(key: SortAnchorKey.self, value: .bounds) { $0 }
        }
        .padding(.horizontal, .spacing20)
        .padding(.vertical, .spacing8)
    }

    private func reload() {
        Task { await viewModel.reload(tab: selectedTab, sort: selectedSort, filter: selectedFilter) }
    }

    /// 삭제 API 호출 → 성공 시 로컬 DB/목록 갱신은 ViewModel에서 처리, 실패 시 에러 토스트만 노출.
    private func deleteReceipt(id: String) async {
        let success = await viewModel.deleteReceipt(id: id)
        if !success {
            toast.showError(String(localized: "receipt.delete.fail"))
        }
    }

    // MARK: - 리스트 영역 (로딩 / 빈 상태 / 카드 목록)

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(Color.brandPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.receipts.isEmpty {
            Text("receipt.empty")
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color.gray500)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: .spacing12) {
                    ForEach(viewModel.receipts) { receipt in
                        ReceiptCard(receipt: receipt) {
                            menuReceiptId = receipt.receiptId
                        }
                        .anchorPreference(key: CardAnchorKey.self, value: .bounds) {
                            [receipt.receiptId: $0]
                        }
                        .task { await viewModel.loadMoreIfNeeded(currentItem: receipt) }
                    }

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .tint(Color.brandPrimary)
                            .padding(.vertical, .spacing16)
                    }
                }
                .padding(.horizontal, .spacing20)
                .padding(.top, .spacing4)
                .padding(.bottom, 92) // 플로팅 하단 바 높이만큼 여백
            }
        }
    }
}

// MARK: - 영수증 카드

private struct ReceiptCard: View {
    let receipt: Receipt
    var onKebab: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                thumbnail

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: .spacing8) {
                        Text(receipt.itemName)
                            .font(.pretendard(.bold, size: 16))
                            .foregroundStyle(Color.gray900)
                            .lineLimit(1)
                        Spacer(minLength: .spacing8)
                        dayBadge
                        kebab
                    }

                    expiryRow
                }
            }

            if let memo = receipt.memo, !memo.isEmpty {
                memoBox(memo)
            }
        }
        .padding(.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    // 썸네일 — imageUrl 있으면 원격 이미지, 없으면 카테고리/소분류 기본 이미지
    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: .roundedLg)
            .fill(Color.gray100)
            .frame(width: 64, height: 64)
            .overlay {
                if let urlString = receipt.imageUrl,
                   let url = URL(string: urlString) {
                    KFImage(url)
                        .placeholder { placeholderIcon }
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholderIcon
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
    }

    /// imageUrl 부재/로딩 실패 시 category+subCategory 기반 로컬 이미지로 폴백
    private var placeholderIcon: some View {
        Image(receipt.deviceImageName)
            .resizable()
            .scaledToFit()
            .padding(10)
    }

    // AS 만료일 | yyyy. MM. dd
    private var expiryRow: some View {
        HStack(spacing: 0) {
            Text("receipt.list.expiry_label")
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray500)
            Text("  |  ")
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray300)
            Text(receipt.formattedExpiresOn)
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray500)
                .lineLimit(1)
        }
    }

    // D-day 배지 (여유=파랑 / 임박=빨강 / 만료=회색)
    @ViewBuilder
    private var dayBadge: some View {
        switch receipt.warrantyBadge {
        case .safe(let dDay):
            badge(text: Text("receipt.list.dday \(dDay)"),
                  bg: .badgeSafeBg, border: .badgeSafeBorder, fg: .badgeSafeText)
        case .expiring(let dDay):
            badge(text: Text("receipt.list.dday \(dDay)"),
                  bg: .badgeWarningBg, border: .badgeWarningBorder, fg: .badgeWarningText)
        case .expired:
            badge(text: Text("receipt.list.expired"),
                  bg: .badgeExpiredBg, border: .badgeExpiredBorder, fg: .badgeExpiredText)
        }
    }

    private func badge(text: Text, bg: Color, border: Color, fg: Color) -> some View {
        text
            .font(.pretendard(.bold, size: 13))
            .foregroundStyle(fg)
            .padding(.horizontal, .spacing12)
            .padding(.vertical, 6)
            .background(bg, in: Capsule())
            .overlay(Capsule().stroke(border, lineWidth: 1))
            .fixedSize()
    }

    private var kebab: some View {
        Button(action: onKebab) {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.gray400)
                .rotationEffect(.degrees(90))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func memoBox(_ memo: String) -> some View {
        Text(memo)
            .font(.pretendard(.regular, size: 14))
            .foregroundStyle(Color.gray500)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .spacing16)
            .padding(.vertical, .spacing12)
            .background(Color.gray50, in: RoundedRectangle(cornerRadius: .roundedLg))
    }
}

// 정렬 드롭다운 위치 앵커
private struct SortAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

// 영수증 카드별 위치 앵커 (receiptId → bounds)
private struct CardAnchorKey: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

#Preview {
    ReceiptListView(selectedTab: .constant(.all), selectedSort: .constant(.default))
}
