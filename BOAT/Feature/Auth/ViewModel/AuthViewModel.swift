//
//  AuthViewModel.swift
//  BOAT
//
//  Android AuthViewModel과 동일 플로우:
//  소셜 로그인 → Firebase 인증 → 약관 화면 → 백엔드 로그인 → 토큰 저장 → 홈
//

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices

@Observable
class AuthViewModel {

    // 화면 라우팅
    private(set) var route: AuthRoute

    // 전환 상태 (화면을 바꾸지 않음)
    var isLoading = false
    var errorMessage: String?

    private let appleSignInHelper = AppleSignInHelper()

    // 약관 동의 후 백엔드 로그인에 사용할 Firebase ID 토큰
    private var pendingFirebaseToken: String?

    private static let termsVersion = "1.0"
    private static let privacyVersion = "1.0"

    init() {
        // 이미 백엔드 토큰을 보유한 경우 바로 홈
        route = KeychainManager.shared.accessToken != nil ? .home : .login
    }

    func dispatch(_ intent: AuthIntent) {
        switch intent {
        case .signInWithGoogle:
            signInWithGoogle()
        case .signInWithApple:
            signInWithApple()
        case .completeTerms(let terms, let privacy, let marketing):
            completeTerms(terms: terms, privacy: privacy, marketing: marketing)
        case .signOut:
            signOut()
        }
    }

    // MARK: - Google Sign In

    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }

        isLoading = true

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self else { return }

            if let error {
                let isCancelled = (error as NSError).code == GIDSignInError.canceled.rawValue
                self.fail(isCancelled ? "login.error.cancelled" : "login.error.google")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.fail("error.auth.google_token_missing")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            self.firebaseSignIn(with: credential, failKey: "login.error.google")
        }
    }

    // MARK: - Apple Sign In

    private func signInWithApple() {
        isLoading = true

        appleSignInHelper.startSignIn { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                let isCancelled = (error as? ASAuthorizationError)?.code == .canceled
                self.fail(isCancelled ? "login.error.cancelled" : "login.error.apple")

            case .success(let (credential, _)):
                self.firebaseSignIn(with: credential, failKey: "login.error.apple")
            }
        }
    }

    // MARK: - Firebase 인증 → Firebase ID 토큰 확보 → 약관 화면

    private func firebaseSignIn(with credential: AuthCredential, failKey: String.LocalizationValue) {
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self else { return }
            if error != nil {
                self.fail(failKey)
                return
            }
            // 약관 동의 후 백엔드 로그인에 쓸 Firebase ID 토큰 확보
            authResult?.user.getIDToken { [weak self] token, _ in
                guard let self else { return }
                guard let token else {
                    self.fail(failKey)
                    return
                }
                self.pendingFirebaseToken = token
                self.isLoading = false
                self.route = .terms
            }
        }
    }

    // MARK: - 약관 동의 완료 → 백엔드 로그인

    private func completeTerms(terms: Bool, privacy: Bool, marketing: Bool) {
        guard let firebaseToken = pendingFirebaseToken else { return }
        isLoading = true

        Task {
            do {
                let tokens: LoginTokenData = try await APIClient.shared.request(
                    AuthTarget.login(
                        idToken: firebaseToken,
                        termsVersion: Self.termsVersion,
                        privacyVersion: Self.privacyVersion,
                        termsAccepted: terms,
                        privacyAccepted: privacy,
                        marketingConsent: marketing
                    )
                )
                KeychainManager.shared.accessToken = tokens.accessToken
                KeychainManager.shared.refreshToken = tokens.refreshToken

                await MainActor.run {
                    self.pendingFirebaseToken = nil
                    self.isLoading = false
                    self.route = .home
                }
            } catch {
                // 서버가 준 에러 문구가 있으면 우선 노출, 없으면 일반 문구
                let message = (error as? LocalizedError)?.errorDescription
                    ?? String(localized: "terms.login_failed")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = message
                }
            }
        }
    }

    // MARK: - Sign Out

    private func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        KeychainManager.shared.clearAll()
        pendingFirebaseToken = nil
        isLoading = false
        route = .login
    }

    // MARK: - Helper

    private func fail(_ messageKey: String.LocalizationValue) {
        isLoading = false
        errorMessage = String(localized: messageKey)
    }
}
