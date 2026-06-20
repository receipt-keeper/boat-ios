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

    let appleSignInHelper = AppleSignInHelper()

    func dispatch(_ intent: AuthIntent) {
        switch intent {
        case .signInWithGoogle:
            signInWithGoogle()
        case .signInWithApple(let result):
            signInWithApple(result: result)
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
                self.state = .error(error.localizedDescription)
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.state = .error("구글 로그인 토큰을 가져올 수 없습니다.")
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

    private func signInWithApple(result: Result<ASAuthorization, Error>) {
        state = .loading

        appleSignInHelper.process(result) { [weak self] processResult in
            guard let self else { return }
            switch processResult {
            case .failure(let error):
                self.state = .error(error.localizedDescription)

            case .success(let (credential, userInfo)):
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
