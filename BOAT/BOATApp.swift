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
                    Text("로그인 성공! 🎉")
                        .font(.title)
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
