//
//  NotificationListView.swift
//  BOAT
//
//  상단 종 아이콘 → 수신 알림 목록. Android NotificationListScreen 대응.
//  GET /api/v1/notifications 로 읽음/미읽음 알림을 모두 불러와 카드형 리스트로 표시.
//  이미 읽은 카드는 흐리게 표시(disabled 스타일)만 하고, 탭은 그대로 허용한다.
//  카드 탭 → 읽음 처리(목록엔 남기고 흐리게 전환) 후 리소스로 라우팅
//  (messageType=marketing → 홈 / receipt+resourceId → 상세 / kind=registration_prompt → 영수증 등록).
//

import SwiftUI

struct NotificationListView: View {

    let onBack: () -> Void

    @State private var viewModel = NotificationListViewModel()
    @State private var detailReceipt: IdentifiedID?
    @State private var showRegister = false

    var body: some View {
        VStack(spacing: 0) {
            topBar

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.brandPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.notifications.isEmpty {
                emptyContent
            } else {
                ScrollView {
                    LazyVStack(spacing: .spacing12) {
                        ForEach(viewModel.notifications) { item in
                            NotificationCard(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { handleTap(item) }
                                // 읽은 알림은 흐리게 표시만 하고, 탭해서 다시 리소스로 이동하는 건 그대로 허용.
                                .opacity(item.isRead ? 0.5 : 1)
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
        .task { await viewModel.load() }
        // 목록 진입 시점에 Red Dot 해제 — 개별 알림을 탭하지 않아도 "봤음" 처리.
        .task { NotificationBadgeStore.shared.markSeen() }
        // 알림 → 영수증 상세
        .fullScreenCover(item: $detailReceipt) { rid in
            ReceiptDetailView(receiptId: rid.id, onBack: { detailReceipt = nil })
        }
        // 알림 → 영수증 등록 (registration_prompt)
        .fullScreenCover(isPresented: $showRegister) {
            ReceiptRegisterView(
                onBack: { showRegister = false },
                onComplete: { showRegister = false }
            )
        }
    }

    // MARK: - 탭 라우팅 (Android route() 대응)

    private func handleTap(_ item: AppNotification) {
        viewModel.markAsRead(item)
        if NotificationRouter.shouldRouteHome(messageType: item.messageType, kind: item.kind) {
            // 홈 탭으로 이동(마케팅 또는 상시 유도 알림) — 목록 자체를 닫고
            // MainTabView가 NotificationRouter를 관찰해 전환.
            NotificationRouter.shared.shouldOpenHome = true
            onBack()
        } else if item.resourceType == "receipt", let id = item.resourceId, !id.isEmpty {
            detailReceipt = IdentifiedID(id: id)
        } else if item.kind == "registration_prompt" {
            showRegister = true
        }
        // 그 외: 특정 리소스를 가리키지 않는 알림 → 이동 없음 (목록에서만 제거)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            Text("notif.list.title")
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
        Text("notif.list.empty")
            .font(.pretendard(.regular, size: 15))
            .foregroundStyle(Color.gray500)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - fullScreenCover(item:)용 식별 래퍼

/// String을 Identifiable로 감싸는 공용 래퍼. NotificationRouter의 푸시 탭 라우팅에서도 재사용.
struct IdentifiedID: Identifiable {
    let id: String
}

// MARK: - Notification Card

private struct NotificationCard: View {
    let item: AppNotification

    var body: some View {
        // 상시 유도 알림(마케팅/등록·미사용·분석 리마인더)은 특정 영수증과 무관한 공지형
        // 카드라 전용 레이아웃(고정 브랜드명/타이틀/본문/고정 안내문)을 쓴다.
        if NotificationRouter.shouldRouteHome(messageType: item.messageType, kind: item.kind) {
            PersistentNotificationCard(item: item)
        } else {
            ReceiptNotificationCard(item: item)
        }
    }
}

/// 특정 영수증에 연결된 일반 알림(만료 임박/AS 안내 등) 카드.
private struct ReceiptNotificationCard: View {
    let item: AppNotification

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(item.productName)
                        .font(.pretendard(.bold, size: 16))
                        .foregroundStyle(Color.gray900)
                        .lineLimit(1)
                    Spacer(minLength: .spacing8)
                    Text(item.displayTime)
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color.gray500)
                }
                Text(item.message)
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray500)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.colorWhite)
        .clipShape(RoundedRectangle(cornerRadius: .rounded2xl))
        .shadow(color: Color.brandPrimary.opacity(0.08), radius: 4, x: 0, y: 0)
    }

    private var thumbnail: some View {
        NotificationThumbnail(imageName: item.imageName)
    }
}

/// 상시 유도 알림(마케팅/등록·미사용·분석 리마인더) 전용 카드.
/// 상단 "보트랩" + 날짜 → 타이틀 → 본문 → 고정 수신거부 안내문 순 배치.
/// 이미지 에셋은 텍스트 블록 첫 줄에 상단 정렬한다.
private struct PersistentNotificationCard: View {
    let item: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            NotificationThumbnail(imageName: item.imageName)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text("notif.persistent.brand")
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color.gray500)
                    Spacer(minLength: .spacing8)
                    Text(item.persistentDisplayDate)
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color.gray500)
                }
                Text(item.productName)
                    .font(.pretendard(.bold, size: 17))
                    .foregroundStyle(Color.gray900)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.message)
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray600)
                    .fixedSize(horizontal: false, vertical: true)
                Text("notif.persistent.footer")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundStyle(Color.gray400)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.colorWhite)
        .clipShape(RoundedRectangle(cornerRadius: .rounded2xl))
        .shadow(color: Color.brandPrimary.opacity(0.08), radius: 4, x: 0, y: 0)
    }
}

private struct NotificationThumbnail: View {
    let imageName: String

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.gray100)
            .frame(width: 56, height: 56)
            .overlay {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
    }
}

#Preview {
    NotificationListView(onBack: {})
        .environment(PermissionManager())
}
