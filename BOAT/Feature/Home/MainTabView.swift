//
//  MainTabView.swift
//  BOAT
//
//  로그인 이후 메인 화면 호스트. Android MainScreen + BoatBottomBar 대응.
//  하단 탭: 목록 / 홈 / 마이 (기본 선택: 홈).
//  ※ 각 탭의 실제 화면 디자인은 보류 — 현재는 플레이스홀더.
//

import SwiftUI

enum MainTab: Hashable {
    case list, home, my
}

struct MainTabView: View {

    let viewModel: AuthViewModel
    @State private var selection: MainTab = .home
    @State private var showAddMenu = false

    // FAB는 홈/목록 탭에서만 노출 (마이 탭 제외)
    private var showFab: Bool {
        selection == .home || selection == .list
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.colorWhite)
            // 영수증 등록 FAB — 콘텐츠 영역(바 위)에 올려 바와 겹치지 않게 함
            .overlay(alignment: .bottomTrailing) {
                if showFab && !showAddMenu {
                    fabButton
                        .padding(.trailing, .spacing16)
                        .padding(.bottom, .spacing16)
                }
            }
            // 커스텀 하단 바 (콘텐츠 + FAB를 자동으로 바 위로 인셋)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BoatBottomBar(selection: $selection)
            }
            // 등록 메뉴 오버레이 (스크림이 바까지 딤 처리)
            .overlay {
                if showAddMenu {
                    ReceiptAddMenu(
                        onDismiss: { showAddMenu = false },
                        onCamera: { showAddMenu = false /* TODO: 카메라 촬영 → 영수증 등록 */ },
                        onGallery: { showAddMenu = false /* TODO: 갤러리 선택 → 영수증 등록 */ }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showAddMenu)
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .list:
            TabPlaceholderView(titleKey: "tab.list")
        case .home:
            TabPlaceholderView(titleKey: "tab.home")
        case .my:
            MyPageView(viewModel: viewModel)
        }
    }

    private var fabButton: some View {
        Button {
            showAddMenu = true
        } label: {
            Image("icPlus")
                .renderingMode(.template)
                .foregroundStyle(Color.colorWhite)
                .frame(width: 56, height: 56)
                .background(Color.gray900, in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .accessibilityLabel(Text("receipt.add"))
    }
}

// MARK: - 임시 플레이스홀더 (목록/홈 디자인 보류)

private struct TabPlaceholderView: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        Text(titleKey)
            .font(.pretendard(.semibold, size: 18))
            .foregroundStyle(Color.gray400)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.colorWhite)
    }
}

// MARK: - 마이 탭 (로그아웃 / 회원 탈퇴)

private struct MyPageView: View {

    let viewModel: AuthViewModel
    @State private var showLogoutDialog = false
    @State private var showDeleteDialog = false
    @State private var toast = BoatToastState()

    var body: some View {
        VStack(spacing: 20) {
            Button("home.sign_out_button") {
                showLogoutDialog = true
            }
            .foregroundStyle(.red)

            Button("home.delete_account") {
                showDeleteDialog = true
            }
            .font(.footnote)
            .foregroundStyle(Color.systemError)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
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
}
