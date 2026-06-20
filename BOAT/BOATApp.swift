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
    @State private var showOCRTest = false

    init() {
        FirebaseApp.configure()
        _isAuthenticated = State(initialValue: Auth.auth().currentUser != nil)
    }

    private var ocrTestButton: some View {
        Button {
            showOCRTest = true
        } label: {
            Label("common.ocr_test", systemImage: "text.viewfinder")
                .font(.footnote)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
        .foregroundStyle(.secondary)
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
                        ocrTestButton
                    }
                } else {
                    LoginView(onAuthenticated: { userInfo in
                        // TODO: userInfo.email, userInfo.name 백엔드 전송
                        isAuthenticated = true
                    })
                    .safeAreaInset(edge: .bottom) {
                        ocrTestButton
                            .padding()
                    }
                }
            }
            .sheet(isPresented: $showOCRTest) {
                OCRTestView()
            }
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
