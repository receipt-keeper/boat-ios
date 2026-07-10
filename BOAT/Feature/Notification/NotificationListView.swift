//
//  NotificationListView.swift
//  BOAT
//
//  상단 종 아이콘 → 수신 알림 목록. Android NotificationListScreen 대응.
//  GET /api/v1/notifications 로 미읽음 알림을 불러와 카드형 리스트로 표시.
//  카드 탭 → 읽음 처리(목록에서 제거) 후 리소스로 라우팅
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
        viewModel.markReadAndRemove(item)
        if item.messageType == "marketing" {
            // 홈 탭으로 이동 — 목록 자체를 닫고 MainTabView가 NotificationRouter를 관찰해 전환.
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
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.gray100)
            .frame(width: 56, height: 56)
            .overlay {
                Image(item.imageName)
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
