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

    @State private var isAuthenticated: Bool = false

    init() {
        FirebaseApp.configure()
        _isAuthenticated = State(initialValue: Auth.auth().currentUser != nil)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    // 추후 메인 화면으로 교체
                    VStack(spacing: 20) {
                        Text("로그인 성공! 🎉")
                            .font(.title)
                        Button("로그아웃") {
                            try? Auth.auth().signOut()
                            GIDSignIn.sharedInstance.signOut()
                            isAuthenticated = false
                        }
                        .foregroundStyle(.red)
                    }
                } else {
                    LoginView(onAuthenticated: {
                        isAuthenticated = true
                    })
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
