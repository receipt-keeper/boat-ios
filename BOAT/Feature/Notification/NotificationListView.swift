//
//  NotificationListView.swift
//  BOAT
//
//  상단 종 아이콘 → 쌓인 푸시 알림 목록 화면. Android NotificationListScreen 대응.
//  NotificationStore에서 최신순 items를 읽어 카드형 리스트로 표시.
//  진입 시 전체 읽음 처리.
//

import SwiftUI

struct NotificationListView: View {
    let onBack: () -> Void
    private let store = NotificationStore.shared

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if store.items.isEmpty {
                emptyContent
            } else {
                ScrollView {
                    VStack(spacing: .spacing12) {
                        ForEach(store.items) { item in
                            NotificationCard(item: item)
                        }
                    }
                    .padding(.horizontal, .spacing20)
                    .padding(.top, .spacing16)
                    .padding(.bottom, .spacing24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray50)
        .onAppear {
            if store.items.isEmpty {
                NotificationItem.mocks.reversed().forEach { store.add($0) }
            }
            store.markAllRead()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            Text("알림")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)
            HStack {
                Button(action: onBack) {
                    Image("icChevronLeft")
                        .renderingMode(.template)
                        .foregroundStyle(Color.gray900)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
        .background(Color.colorWhite)
    }

    // MARK: - Empty State

    private var emptyContent: some View {
        Text("수신된 알림 내역이 없습니다.")
            .font(.pretendard(.regular, size: 14))
            .foregroundStyle(Color.gray400)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Notification Card

private struct NotificationCard: View {
    let item: NotificationItem

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(item.productName)
                        .font(.pretendard(.bold, size: 16))
                        .foregroundStyle(Color.gray900)
                        .lineLimit(1)
                    Spacer()
                    Text(item.formattedDate)
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color.gray500)
                }
                Text(item.message)
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray500)
                    .lineLimit(1)
            }
        }
        .padding(.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.colorWhite)
        .clipShape(RoundedRectangle(cornerRadius: .rounded2xl))
        .shadow(color: Color(hex: "#007EFF").opacity(0.08), radius: 4, x: 0, y: 0)
    }

    // 실제 썸네일이 없는 경우 카테고리 아이콘 placeholder (Android ic_gallery 대응)
    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray100)
            Image(systemName: item.category.sfSymbol)
                .font(.system(size: 24))
                .foregroundStyle(Color.gray400)
        }
        .frame(width: 56, height: 56)
    }
}

// MARK: - Helpers

private extension NotificationItem {
    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f.string(from: receivedAt)
    }
}

private extension DeviceCategory {
    var sfSymbol: String {
        switch self {
        case .kitchen: return "refrigerator"
        case .laundry: return "washer"
        case .living:  return "air.conditioner.horizontal"
        case .it:      return "ipad"
        case .other:   return "tag"
        }
    }
}

// MARK: - Preview

#Preview("목록 있음") {
    let store = NotificationStore.shared
    store.clear()
    NotificationItem.mocks.reversed().forEach { store.add($0) }
    return NotificationListView(onBack: {})
}

#Preview("빈 목록") {
    NotificationStore.shared.clear()
    return NotificationListView(onBack: {})
}
