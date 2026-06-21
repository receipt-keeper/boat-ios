//
//  AuthViewModel.swift
//  BOAT
//

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices

@Observable
class AuthViewModel {

    var state: AuthState = .idle

    private let appleSignInHelper = AppleSignInHelper()

    func dispatch(_ intent: AuthIntent) {
        switch intent {
        case .signInWithGoogle:
            signInWithGoogle()
        case .signInWithApple:
            signInWithApple()
        case .signOut:
            signOut()
        }
    }

    // MARK: - Google Sign In

    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }

        state = .loading

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self else { return }

            if let error {
                // 사용자 취소와 일반 실패를 구분
                let isCancelled = (error as NSError).code == GIDSignInError.canceled.rawValue
                self.state = .error(String(localized: isCancelled
                    ? "login.error.cancelled"
                    : "login.error.google"))
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.state = .error(String(localized: "error.auth.google_token_missing"))
                return
            }

            // 이메일 + 이름 추출 (Google은 매 로그인마다 제공)
            let userInfo = SocialUserInfo(
                email: user.profile?.email,
                name: user.profile?.name,
                provider: .google
            )

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { [weak self] _, error in
                guard let self else { return }
                if let error {
                    self.state = .error(error.localizedDescription)
                } else {
                    self.state = .authenticated(userInfo)
                }
            }
        }
    }

    // MARK: - Apple Sign In

    private func signInWithApple() {
        state = .loading

        appleSignInHelper.startSignIn { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                // 사용자 취소와 일반 실패를 구분
                let isCancelled = (error as? ASAuthorizationError)?.code == .canceled
                self.state = .error(String(localized: isCancelled
                    ? "login.error.cancelled"
                    : "login.error.apple"))

            case .success(let (credential, userInfo)):
                Auth.auth().signIn(with: credential) { [weak self] _, error in
                    guard let self else { return }
                    if error != nil {
                        self.state = .error(String(localized: "login.error.apple"))
                    } else {
                        self.state = .authenticated(userInfo)
                    }
                }
            }
        }
    }

    // MARK: - Sign Out

    private func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            state = .unauthenticated
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
