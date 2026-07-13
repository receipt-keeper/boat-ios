//
//  BOATApp.swift
//  BOAT
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct BOATApp: App {

    // FCM 푸시 수신(APNs 등록 / MessagingDelegate / UNUserNotificationCenterDelegate)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    @State private var permissionManager = PermissionManager()

    init() {
        FirebaseApp.configure()
        // 이 기기에서 최초 실행이면 Firebase Analytics에 app_install 이벤트 1회 기록.
        InstallAnalytics.logInstallIfNeeded()
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
                // 앱 시작 시에는 권한 '상태 확인'만 한다. (실제 요청은 각 기능 진입 시점)
                // 카메라=촬영 버튼 탭 시, 알림=AS 알림 설정 시 요청 — App Store 심사 가이드(5.1.1) 준수.
                .task {
                    await permissionManager.refreshAll()
                }
                // 광고 SDK 시작 전 UMP 동의(필요 시 폼 노출) → ATT 권한 순서로 확인.
                .task {
                    await ConsentManager.requestConsentAndStart()
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

