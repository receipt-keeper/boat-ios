//
//  BOATApp.swift
//  BOAT
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@main
struct BOATApp: App {

    @Environment(\.scenePhase) private var scenePhase

    @State private var isAuthenticated: Bool = false
    @State private var permissionManager = PermissionManager()

    init() {
        FirebaseApp.configure()
        _isAuthenticated = State(initialValue: Auth.auth().currentUser != nil)
        // UIKit 레벨 tint — 시스템 권한 다이얼로그(Allow 버튼) 등 UIAlertController에 적용
        UIView.appearance().tintColor = UIColor(Color.brandPrimary)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    // 추후 메인 화면으로 교체
                    VStack(spacing: 20) {
                        Text("home.login_success")
                            .font(.title)
                        Button("home.sign_out_button") {
                            try? Auth.auth().signOut()
                            GIDSignIn.sharedInstance.signOut()
                            isAuthenticated = false
                        }
                        .foregroundStyle(.red)
                    }
                } else {
                    LoginView(onAuthenticated: { userInfo in
                        // TODO: userInfo.email, userInfo.name 백엔드 전송
                        isAuthenticated = true
                    })
                }
            }
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
