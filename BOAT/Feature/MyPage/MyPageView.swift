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
    var name: String? = nil
    var email: String? = nil

    @State private var showLogoutDialog = false
    @State private var showDeleteDialog = false
    @State private var showNotificationSettings = false
    @State private var toast = BoatToastState()

    private var nameText: String {
        let trimmed = name?.trimmingCharacters(in: .whitespaces)
        return (trimmed?.isEmpty == false ? trimmed : nil) ?? String(localized: "mypage.name_placeholder")
    }
    private var emailText: String {
        let trimmed = email?.trimmingCharacters(in: .whitespaces)
        return (trimmed?.isEmpty == false ? trimmed : nil) ?? String(localized: "mypage.email_placeholder")
    }

    var body: some View {
        VStack(spacing: 0) {
            BoatHeader(
                title: "mypage.title",
                onSearch: { /* TODO: 검색 */ },
                onNotification: { /* TODO: 알림 */ }
            )

            profile

            // 섹션 구분 밴드
            Color.gray50
                .frame(height: 8)

            sectionLabel("mypage.section.notification")
            settingRow("mypage.section.notification") { showNotificationSettings = true }

            Rectangle()
                .fill(Color.gray200)
                .frame(height: 1)
                .padding(.horizontal, .spacing20)

            sectionLabel("mypage.section.help")
            settingRow("mypage.inquiry") { /* TODO: 1:1 문의하기 */ }
            settingRow("mypage.terms") { /* TODO: 서비스 이용약관 */ }

            Spacer()

            bottomButtons
                .padding(.bottom, .spacing24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        .fullScreenCover(isPresented: $showNotificationSettings) {
            NotificationSettingsView(onBack: { showNotificationSettings = false })
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
            // 프로필 이미지 (디자이너 제공 전 임시)
            Circle()
                .fill(Color.brandSenary)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "sailboat.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.brandPrimary)
                }

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
