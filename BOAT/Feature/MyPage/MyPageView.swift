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
    private let store = UserStore.shared

    @Environment(\.openURL) private var openURL

    @State private var showLogoutDialog = false
    @State private var showDeleteDialog = false
    @State private var showNotificationSettings = false
    @State private var showReceiptRegister = false
    @State private var showPromoSheet = false
    @State private var hasUnreadNotification = false
    @State private var toast = BoatToastState()

    private let inquiryEmail = "team.swyp8.app@gmail.com"

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
                showUnreadBadge: hasUnreadNotification,
                onSearch: onSearch,
                onNotification: onNotification
            )

            profile

            analysisBanner
                .padding(.horizontal, .spacing20)
                .padding(.bottom, .spacing20)

            // 섹션 구분 — 두꺼운 회색 배경 갭
            Rectangle()
                .fill(Color.gray100)
                .frame(height: .spacing8)

            sectionLabel("mypage.section.settings")
            settingRow("mypage.section.notification") { showNotificationSettings = true }

            Rectangle()
                .fill(Color.gray200)
                .frame(height: 1)
                .padding(.horizontal, .spacing20)

            sectionLabel("mypage.section.help")
            settingRow("mypage.inquiry") { sendInquiryMail() }
            settingRow("mypage.terms") { /* TODO: 서비스 이용약관 */ }

            Spacer()

            bottomButtons
                .padding(.bottom, 92) // 플로팅 하단 바 높이만큼 여백
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        .task { await refreshUnreadState() }
        .fullScreenCover(isPresented: $showNotificationSettings) {
            NotificationSettingsView(onBack: { showNotificationSettings = false })
        }
        .fullScreenCover(isPresented: $showReceiptRegister) {
            ReceiptRegisterView(
                onBack: { showReceiptRegister = false },
                onComplete: { showReceiptRegister = false }
            )
        }
        .sheet(isPresented: $showPromoSheet) {
            ReceiptPromoSheet(
                onClose: { showPromoSheet = false },
                onRegister: {
                    showPromoSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showReceiptRegister = true
                    }
                }
            )
            .presentationDetents([.height(600)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.colorWhite)
        }
        .boatToastHost(toast)
        .boatDialog(
            isPresented: $showLogoutDialog,
            title: "dialog.logout.title",
            message: "dialog.logout.message",
            confirmText: "home.sign_out_button",
            confirmColor: .brandPrimary,
            cancelText: "common.cancel",
            cancelColor: .brandPrimary,
            onConfirm: { viewModel.dispatch(.signOut) }
        )
        .boatDialog(
            isPresented: $showDeleteDialog,
            title: "dialog.delete.title",
            message: "dialog.delete.message",
            confirmText: "dialog.delete.confirm",
            confirmColor: .brandPrimary,
            cancelText: "dialog.delete.cancel",
            cancelColor: .brandPrimary,
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
            Image("img_profile")
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: .spacing4) {
                Text(nameText)
                    .font(.pretendard(.bold, size: 18))
                    .foregroundStyle(Color.gray900)
                Text(emailText)
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray800)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .spacing20)
        .padding(.vertical, .spacing20)
    }

    // MARK: - 영수증 분석 잔여 횟수 배너

    private var analysisBanner: some View {
        HStack(spacing: .spacing8) {
            Image("icSparkle")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)

            (
                Text("mypage.analysis_remaining_pre")
                    .foregroundStyle(Color.gray900)
                + Text("mypage.analysis_remaining_count \(CreditStore.shared.current?.remainingCount ?? 3)")
                    .foregroundStyle(Color.brandPrimary)
                + Text("mypage.analysis_remaining_post")
                    .foregroundStyle(Color.gray900)
            )
            .font(.pretendard(.semibold, size: 15))

            Spacer(minLength: .spacing8)

            Button {
                showPromoSheet = true
            } label: {
                Text("mypage.analysis_view")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color.colorWhite)
                    .padding(.horizontal, .spacing20)
                    .padding(.vertical, .spacing8)
                    .background(Color.brandPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .spacing16)
        .frame(height: 52)
        .background(Color.brandSenary, in: RoundedRectangle(cornerRadius: .roundedXl))
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
            .padding(.horizontal, .spacing20)
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
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.gray400)
            }
            .padding(.horizontal, .spacing20)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 알림 미읽음 배지

    /// 종 아이콘 우상단 빨간 점 — 미읽음 알림 존재 여부만 확인(개수 표시 없음).
    private func refreshUnreadState() async {
        let unread = (try? await NotificationRepository.shared.fetchUnread()) ?? []
        hasUnreadNotification = !unread.isEmpty
    }

    // MARK: - 1:1 문의 메일

    private func sendInquiryMail() {
        let subject = String(localized: "mypage.inquiry_subject")
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "mailto:\(inquiryEmail)?subject=\(encodedSubject)") else { return }
        openURL(url) { accepted in
            if !accepted {
                toast.showError(String(localized: "mypage.inquiry_mail_failed"))
            }
        }
    }

    // MARK: - 로그아웃 | 회원탈퇴

    private var bottomButtons: some View {
        HStack(spacing: .spacing12) {
            bottomButton("home.sign_out_button") { showLogoutDialog = true }
            Text("|")
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray200)
            bottomButton("mypage.withdraw") { showDeleteDialog = true }
        }
        .frame(maxWidth: .infinity)
    }

    private func bottomButton(_ key: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(key)
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray500)
        }
        .buttonStyle(.plain)
    }
}
