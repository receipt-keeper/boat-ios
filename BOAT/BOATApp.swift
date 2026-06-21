//
//  BOATApp.swift
//  BOAT
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct BOATApp: App {

    @Environment(\.scenePhase) private var scenePhase

    @State private var permissionManager = PermissionManager()

    init() {
        FirebaseApp.configure()
        // UIKit 레벨 tint — 시스템 권한 다이얼로그(Allow 버튼) 등 UIAlertController에 적용
        UIView.appearance().tintColor = UIColor(Color.brandPrimary)
        #if DEBUG
        print("🚀 BOAT 실행 (DEBUG 로깅 활성화)")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Color.brandPrimary)
                .environment(permissionManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                // 앱 최초 시작 시 권한 상태 확인 및 요청
                .task {
                    await permissionManager.refreshAll()
                    if permissionManager.notificationStatus.canRequest {
                        await permissionManager.requestNotificationPermission()
                    }
                    if permissionManager.photoStatus.canRequest {
                        await permissionManager.requestPhotoPermission()
                    }
                }
                // 포그라운드 복귀 시마다 권한 상태 재확인 (설정에서 바뀌었을 수 있음)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await permissionManager.refreshAll() }
                    }
                }
        }
    }
}

// MARK: - 인증 플로우 라우팅

private struct RootView: View {

    @State private var viewModel = AuthViewModel()

    var body: some View {
        Group {
            switch viewModel.route {
            case .login:
                LoginView(viewModel: viewModel)
            case .terms:
                TermsView(viewModel: viewModel)
            case .home:
                HomePlaceholderView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut, value: viewModel.route)
    }
}

// MARK: - 홈 (추후 메인 화면으로 교체)

private struct HomePlaceholderView: View {

    let viewModel: AuthViewModel
    @State private var showLogoutDialog = false
    @State private var showDeleteDialog = false
    @State private var toast = BoatToastState()

    var body: some View {
        VStack(spacing: 20) {
            Text("home.login_success")
                .font(.title)
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
