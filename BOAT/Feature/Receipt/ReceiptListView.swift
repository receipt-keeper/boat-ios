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
    @State private var selectedFilter: ReceiptFilter = .all
    @State private var sortExpanded = false

    // TODO: 실제 영수증 데이터 연동
    private let receiptCount = 0

    var body: some View {
        VStack(spacing: 0) {
            // 헤더 + inner tab (흰 배경)
            VStack(spacing: 0) {
                BoatHeader(
                    title: "tab.list",
                    onSearch: { /* TODO: 검색 */ },
                    onNotification: { /* TODO: 알림 */ }
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

            // 리스트 영역 (데이터 없으면 placeholder)
            ZStack {
                if receiptCount == 0 {
                    Text("receipt.empty")
                        .font(.pretendard(.medium, size: 16))
                        .foregroundStyle(Color.gray500)
                }
                // TODO: 영수증 카드 리스트
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.gray50)
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
    }

    // MARK: - 정렬 드롭다운 (커스텀)

    private var sortDropdown: some View {
        VStack(spacing: 0) {
            ForEach(ReceiptSort.allCases, id: \.self) { sort in
                Button {
                    selectedSort = sort
                    sortExpanded = false
                    // TODO: 정렬 적용
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
                Text("\(receiptCount)")
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
