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
                MainTabView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut, value: viewModel.route)
    }
}

