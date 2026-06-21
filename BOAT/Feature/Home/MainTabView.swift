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

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
        Self.configureTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $selection) {
            TabPlaceholderView(titleKey: "tab.list")
                .tabItem {
                    Image("icList")
                    Text("tab.list")
                }
                .tag(MainTab.list)

            TabPlaceholderView(titleKey: "tab.home")
                .tabItem {
                    Image("icHome")
                    Text("tab.home")
                }
                .tag(MainTab.home)

            MyPageView(viewModel: viewModel)
                .tabItem {
                    Image("icProfile")
                    Text("tab.my")
                }
                .tag(MainTab.my)
        }
        .tint(Color.brandPrimary)
    }

    /// 선택=brandPrimary / 비선택=gray400 / 배경=흰색 (Android BoatBottomBar 동일)
    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.colorWhite)

        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor(Color.gray400)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.gray400)]
        item.selected.iconColor = UIColor(Color.brandPrimary)
        item.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brandPrimary)]

        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
