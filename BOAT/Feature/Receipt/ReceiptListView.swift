//
//  ReceiptListView.swift
//  BOAT
//
//  목록 탭 — 헤더 + 보증상태 inner tab + 카테고리 필터 칩 + 카운트/정렬 + 리스트(placeholder).
//  Android ReceiptListScreen 대응.
//

import SwiftUI

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
    // 케밥 메뉴(수정/삭제) + 삭제 확인 다이얼로그
    @State private var menuReceipt: Receipt?
    @State private var pendingDeleteId: String?
    @State private var showDeleteConfirm = false
    @State private var editReceipt: Receipt?
    @State private var detailReceipt: Receipt?
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
        // 케밥 → 수정/삭제 액션시트 (상세 화면과 동일한 패턴)
        .overlay {
            if let receipt = menuReceipt {
                actionSheetOverlay(for: receipt)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: menuReceipt)
        // 삭제 확인 다이얼로그
        .boatDialog(
            isPresented: $showDeleteConfirm,
            title: "detail.delete_confirm_title",
            message: "detail.delete_confirm_message",
            confirmText: "detail.menu_delete",
            confirmColor: .brandPrimary,
            cancelText: "common.cancel",
            onConfirm: {
                if let id = pendingDeleteId {
                    Task { await deleteReceipt(id: id) }
                }
            }
        )
        .boatToastHost(toast)
        // 카드 탭 → 영수증 상세
        .fullScreenCover(item: $detailReceipt) { receipt in
            ReceiptDetailView(
                receiptId: receipt.receiptId,
                onBack: { detailReceipt = nil },
                onDeleted: {
                    // 상세는 onBack으로 닫히므로 여기서는 목록 동기화 + 삭제 토스트만
                    viewModel.removeFromList(id: receipt.receiptId)
                    toast.show(String(localized: "detail.deleted_toast"), type: .info)
                }
            )
        }
        // 케밥 → 수정하기
        .fullScreenCover(item: $editReceipt) { receipt in
            ReceiptEditView(
                receipt: receipt,
                onBack: { editReceipt = nil },
                onUpdated: {
                    editReceipt = nil
                    reload()
                    toast.show(String(localized: "detail.updated_toast"), type: .info)
                }
            )
        }
    }

    // MARK: - 케밥 액션시트 (수정하기 / 삭제하기 / 닫기)

    private func actionSheetOverlay(for receipt: Receipt) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { menuReceipt = nil }

            VStack(spacing: .spacing8) {
                VStack(spacing: 0) {
                    actionRow("detail.menu_edit", color: .gray900) {
                        menuReceipt = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            editReceipt = receipt
                        }
                    }
                    Rectangle().fill(Color.gray200).frame(height: 1)
                    actionRow("detail.menu_delete", color: .systemError) {
                        menuReceipt = nil
                        pendingDeleteId = receipt.receiptId
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            showDeleteConfirm = true
                        }
                    }
                }
                .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))

                actionRow("detail.menu_close", color: .gray900) { menuReceipt = nil }
                    .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
            }
            .padding(.horizontal, .spacing16)
            .padding(.bottom, .spacing16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func actionRow(_ key: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(key)
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    /// 삭제 API 호출 → 성공 시 로컬 DB/목록 갱신은 ViewModel에서 처리 + 삭제 토스트, 실패 시 에러 토스트.
    private func deleteReceipt(id: String) async {
        let success = await viewModel.deleteReceipt(id: id)
        if success {
            toast.show(String(localized: "detail.deleted_toast"), type: .info)
        } else {
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
                        ReceiptCard(
                            receipt: receipt,
                            onKebab: { menuReceipt = receipt },
                            onTap: { detailReceipt = receipt }
                        )
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

/// 목록/검색 결과 공용 영수증 카드. 검색 결과에서는 케밥을 숨긴다(showKebab: false).
struct ReceiptCard: View {
    let receipt: Receipt
    var showKebab: Bool = true
    var onKebab: () -> Void = {}
    var onTap: () -> Void = {}

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
                        DDayBadge(dDay: receipt.warrantyDDay)
                        if showKebab { kebab }
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
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    // 썸네일 — 카테고리/소분류 기본 이미지 (실제 첨부 이미지는 상세 화면에서만 노출)
    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: .roundedLg)
            .fill(Color.gray100)
            .frame(width: 64, height: 64)
            .overlay { placeholderIcon }
            .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
    }

    /// category+subCategory 기반 로컬 이미지
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

#Preview {
    ReceiptListView(selectedTab: .constant(.all), selectedSort: .constant(.default))
}
