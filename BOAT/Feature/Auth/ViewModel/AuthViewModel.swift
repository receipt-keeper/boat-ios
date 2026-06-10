//
//  AuthViewModel.swift
//  BOAT
//

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@Observable
class AuthViewModel {

    var state: AuthState = .idle

    func dispatch(_ intent: AuthIntent) {
        switch intent {
        case .signInWithGoogle:
            signInWithGoogle()
        case .signInWithApple:
            break // 추후 구현
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

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { [weak self] _, error in
                guard let self else { return }
                if let error {
                    self.state = .error(error.localizedDescription)
                } else {
                    self.state = .authenticated
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
