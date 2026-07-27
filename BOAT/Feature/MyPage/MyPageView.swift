//
//  MyPageView.swift
//  BOAT
//
//  마이 탭 — 공통 헤더 + 프로필 + 알림설정/도움말 메뉴 + 로그아웃/회원탈퇴.
//  Android MyPageScreen 대응. 이름·이메일 없으면 플레이스홀더로 표시(임시 처리).
//

import SwiftUI

struct MyPageView: View {

    let viewModel: AuthViewModel
    var onSearch: () -> Void = {}
    var onNotification: () -> Void = {}
    /// 등록 완료 후 메인 탭을 홈으로 전환할 때 사용한다.
    var onGoHome: () -> Void = {}
    private let store = UserStore.shared

    @Environment(\.openURL) private var openURL

    @State private var showLogoutDialog = false
    @State private var showDeleteDialog = false
    @State private var showNotificationSettings = false
    @State private var showReceiptRegister = false
    @State private var showPromoSheet = false
    @State private var showTermsOfService = false
    @State private var toast = BoatToastState()

    private let inquiryFormURLString = "https://forms.gle/HKZgwcqCPsEqBYfo9"

    private var nameText: String {
        let name = store.current?.displayName.trimmingCharacters(in: .whitespaces)
        return (name?.isEmpty == false ? name : nil) ?? String(localized: "mypage.name_placeholder")
    }
    private var emailText: String {
        let email = store.current?.email.trimmingCharacters(in: .whitespaces)
        return (email?.isEmpty == false ? email : nil) ?? String(localized: "mypage.email_placeholder")
    }

    var body: some View {
        VStack(spacing: 0) {
            BoatHeader(
                title: "mypage.title",
                showUnreadBadge: NotificationBadgeStore.shared.hasUnread,
                onSearch: onSearch,
                onNotification: onNotification
            )

            profile

            analysisBanner
                .padding(.horizontal, .spacing24)
                .padding(.bottom, .spacing20)

            // 섹션 구분 — 두꺼운 회색 배경 갭
            Rectangle()
                .fill(Color.gray50)
                .frame(height: .spacing8)

            sectionLabel("mypage.section.settings")
            settingRow("mypage.section.notification") { showNotificationSettings = true }

            Rectangle()
                .fill(Color.gray200)
                .frame(height: 1)
                .padding(.horizontal, .spacing24)

            sectionLabel("mypage.section.help")
            settingRow("mypage.inquiry") { openInquiryForm() }
            settingRow("mypage.terms") { showTermsOfService = true }

            Spacer()

            bottomButtons
                .padding(.bottom, 96) // 플로팅 하단 바 높이만큼 여백
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        .task { await NotificationBadgeStore.shared.refresh() }
        .fullScreenCover(isPresented: $showNotificationSettings) {
            NotificationSettingsView(onBack: { showNotificationSettings = false })
        }
        .fullScreenCover(isPresented: $showTermsOfService) {
            TermsOfServiceView(onBack: { showTermsOfService = false })
        }
        .fullScreenCover(isPresented: $showReceiptRegister) {
            ReceiptRegisterView(
                onBack: { showReceiptRegister = false },
                onComplete: {
                    showReceiptRegister = false
                    onGoHome()
                }
            )
        }
        .boatBottomSheet(isPresented: $showPromoSheet, onDismiss: { showPromoSheet = false }) {
            ReceiptPromoSheet(
                onClose: { showPromoSheet = false },
                onRegister: {
                    showPromoSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showReceiptRegister = true
                    }
                }
            )
        }
        .boatToastHost(toast)
        .boatDialog(
            isPresented: $showLogoutDialog,
            title: "dialog.logout.title",
            message: "dialog.logout.message",
            confirmText: "home.sign_out_button",
            confirmColor: .brandPrimary,
            cancelText: "common.cancel",
            cancelColor: .gray600,
            onConfirm: { viewModel.dispatch(.signOut) }
        )
        .boatDialog(
            isPresented: $showDeleteDialog,
            title: "dialog.delete.title",
            message: "dialog.delete.message",
            confirmText: "dialog.delete.confirm",
            confirmColor: .brandPrimary,
            cancelText: "dialog.delete.cancel",
            cancelColor: .gray600,
            onConfirm: { viewModel.dispatch(.deleteAccount) }
        )
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toast.showError(message)
                viewModel.errorMessage = nil
            }
        }
    }

    // MARK: - 프로필

    private var profile: some View {
        HStack(spacing: .spacing16) {
            profileAvatar
                .frame(width: 54, height: 54)
                .clipShape(Circle())
                .background(Color.brandSenary, in: Circle())

            VStack(alignment: .leading, spacing: .spacing4) {
                Text(nameText)
                    .font(.pretendard(.bold, size: 18))
                    .foregroundStyle(Color.gray900)
                Text(emailText)
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray900)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .spacing24)
        .padding(.vertical, .spacing20)
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let urlString = store.current?.profileImageUrl, !urlString.isEmpty, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Image("img_profile").resizable().scaledToFill()
                }
            }
        } else {
            Image("img_profile").resizable().scaledToFill()
        }
    }

    // MARK: - 영수증 분석 잔여 횟수 배너

    private var analysisBanner: some View {
        HStack(spacing: .spacing8) {
            GifImageView(name: "shiny_white")
                .frame(width: 20, height: 20)

            Text("mypage.analysis_remaining_pre")
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(Color.gray900)
            + Text("mypage.analysis_remaining_count \(CreditStore.shared.current?.remainingCount ?? 3)")
                .font(.pretendard(.bold, size: 14))
                .foregroundStyle(Color.brandPrimary)
            + Text("mypage.analysis_remaining_post")
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(Color.gray900)

            Spacer(minLength: .spacing8)

            Button {
                showPromoSheet = true
            } label: {
                Text("mypage.analysis_view")
                    .font(.pretendard(.semibold, size: 13))
                    .foregroundStyle(Color.colorWhite)
                    .padding(.horizontal, .spacing16)
                    .padding(.vertical, .spacing8)
                    .background(Color.brandPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .spacing16)
        .frame(height: 53)
        .background(Color.gray50, in: RoundedRectangle(cornerRadius: .roundedXl))
        .overlay(
            RoundedRectangle(cornerRadius: .roundedXl)
                .stroke(Color.brandTertiary, lineWidth: 1)
        )
    }

    // MARK: - 섹션

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.pretendard(.regular, size: 13))
            .foregroundStyle(Color.gray500)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .spacing24)
            .padding(.top, .spacing24)
            .padding(.bottom, .spacing8)
    }

    private func settingRow(_ key: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(key)
                    .font(.pretendard(.medium, size: 16))
                    .foregroundStyle(Color.gray900)
                Spacer(minLength: 0)
                Image("chevron_right")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 9, height: 15)
                    .foregroundStyle(Color.gray600)
            }
            .padding(.horizontal, .spacing24)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 1:1 문의 (구글 폼)

    private func openInquiryForm() {
        guard let url = URL(string: inquiryFormURLString) else { return }
        openURL(url) { accepted in
            if !accepted {
                toast.showError(String(localized: "mypage.inquiry_mail_failed"))
            }
        }
    }

    // MARK: - 로그아웃 | 회원탈퇴

    private var bottomButtons: some View {
        HStack(spacing: 0) {
            bottomButton("home.sign_out_button") { showLogoutDialog = true }
            Text("  |  ")
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray600)
            bottomButton("mypage.withdraw") { showDeleteDialog = true }
        }
        .frame(maxWidth: .infinity)
    }

    private func bottomButton(_ key: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(key)
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray600)
        }
        .buttonStyle(.plain)
    }
}
