//
//  AuthViewModel.swift
//  BOAT
//
//  소셜 로그인 플로우:
//  Firebase 인증 → POST /auth/login
//    ├─ 200 기존 회원 → 토큰 저장 → 홈
//    ├─ 404 미가입 → 약관 화면 (pendingFirebaseToken 보관)
//    └─ 기타 오류 → 에러 토스트
//  약관 동의 완료 → POST /auth/signup → 토큰 저장 → 홈
//

import Foundation
import Network
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

    // 네트워크 상태 모니터
    private let pathMonitor = NWPathMonitor()
    private var isNetworkAvailable = true

    // 404(미가입) 시 약관 화면에서 signup 호출에 사용할 Firebase ID 토큰
    private var pendingFirebaseToken: String?

    private static let termsVersion   = "2026-06-01"
    private static let privacyVersion = "2026-06-01"

    init() {
        // 이미 백엔드 토큰을 보유한 경우 바로 홈
        let hasExistingToken = KeychainManager.shared.accessToken != nil
        route = hasExistingToken ? .home : .login
        // 알림 권한 다이얼로그의 "재실행 시에만 노출" 판단 기준 — 이번 프로세스 시작 시점에
        // 이미 로그인 토큰이 있었는지를 1회만 기록한다(이후 값 변경 없음).
        AppLaunchState.wasLoggedInAtProcessStart = hasExistingToken

        // 네트워크 상태 실시간 감지
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        pathMonitor.start(queue: DispatchQueue.global(qos: .background))

        // 앱 시작 시 이미 로그인 상태면 사용자 정보 동기화
        if route == .home {
            Task { try? await UserRepository.shared.refreshUser() }
        }

        // 토큰 재발급 실패(세션 만료) → 강제 로그인 화면 복귀
        NotificationCenter.default.addObserver(
            forName: .boatSessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pendingFirebaseToken = nil
            self?.isLoading = false
            UserStore.shared.clear()
            self?.route = .login
        }
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
        case .deleteAccount:
            deleteAccount()
        }
    }

    // MARK: - Google Sign In

    private func signInWithGoogle() {
        guard isNetworkAvailable else { fail("error.api.network"); return }
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
        guard isNetworkAvailable else { fail("error.api.network"); return }
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

    // MARK: - Firebase 인증 → Firebase ID 토큰 확보 → 백엔드 로그인 시도

    private func firebaseSignIn(with credential: AuthCredential, failKey: String.LocalizationValue) {
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self else { return }
            if error != nil {
                self.fail(failKey)
                return
            }
            authResult?.user.getIDToken { [weak self] token, _ in
                guard let self else { return }
                guard let token else {
                    self.fail(failKey)
                    return
                }
                // Firebase 토큰 확보 → 백엔드 login 시도
                Task { await self.attemptBackendLogin(firebaseToken: token, failKey: failKey) }
            }
        }
    }

    // MARK: - 백엔드 login 시도 (Android loginOrRedirectToSignup 대응)

    private func attemptBackendLogin(firebaseToken: String, failKey: String.LocalizationValue) async {
        do {
            let tokens: LoginTokenData = try await APIClient.shared.request(
                AuthTarget.login(idToken: firebaseToken)
            )
            // 200 기존 회원 → 토큰 저장 후 홈
            KeychainManager.shared.accessToken = tokens.accessToken
            KeychainManager.shared.refreshToken = tokens.refreshToken
            try? await UserRepository.shared.refreshUser()
            await MainActor.run {
                self.isLoading = false
                self.route = .home
            }
        } catch {
            if let apiError = error as? APIError, case .server(404, _, _, _) = apiError {
                // 404 미가입 → 약관 동의 화면으로
                await MainActor.run {
                    self.pendingFirebaseToken = firebaseToken
                    self.isLoading = false
                    self.route = .terms
                }
            } else {
                // 그 외 오류 → 에러 토스트
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? String(localized: failKey)
                }
            }
        }
    }

    // MARK: - 약관 동의 완료 → 회원가입 API

    private func completeTerms(terms: Bool, privacy: Bool, marketing: Bool) {
        guard let firebaseToken = pendingFirebaseToken else { return }
        isLoading = true

        Task {
            do {
                let tokens: LoginTokenData = try await APIClient.shared.request(
                    AuthTarget.signup(
                        idToken:          firebaseToken,
                        termsVersion:     Self.termsVersion,
                        privacyVersion:   Self.privacyVersion,
                        termsAccepted:    terms,
                        privacyAccepted:  privacy,
                        marketingConsent: marketing
                    )
                )
                KeychainManager.shared.accessToken = tokens.accessToken
                KeychainManager.shared.refreshToken = tokens.refreshToken
                try? await UserRepository.shared.refreshUser()
                await MainActor.run {
                    self.pendingFirebaseToken = nil
                    self.isLoading = false
                    self.route = .home
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription
                    ?? String(localized: "terms.login_failed")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = message
                }
            }
        }
    }

    // MARK: - Delete Account (회원 탈퇴)

    private func deleteAccount() {
        isLoading = true

        Task {
            do {
                try await APIClient.shared.requestVoid(UserTarget.deleteAccount)
                try? Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
                KeychainManager.shared.clearAll()
                FCMTokenStore.registeredToken = nil // 서버는 계정 삭제 시 디바이스도 정리 — 로컬 캐시만 비움
                UserStore.shared.clear()
                await MainActor.run {
                    self.pendingFirebaseToken = nil
                    self.isLoading = false
                    self.route = .login
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = String(localized: "error.delete_account")
                }
            }
        }
    }

    // MARK: - Sign Out

    private func signOut() {
        let refreshToken = KeychainManager.shared.refreshToken

        // 인증 헤더가 필요한 정리(FCM 디바이스 해제 → 세션 revoke)를 토큰 삭제 "전"에 수행한다.
        // 로컬 상태는 아래에서 즉시 초기화하므로 UX는 지연되지 않는다(best-effort 백그라운드).
        Task {
            await FCMDeviceManager.shared.unregister()
            if let refreshToken, !refreshToken.isEmpty {
                try? await APIClient.shared.requestVoid(AuthTarget.logout(refreshToken: refreshToken))
            }
            try? Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            KeychainManager.shared.clearAll()
        }

        // 즉시 로컬 로그아웃 (네트워크 실패로 갇히지 않도록)
        UserStore.shared.clear()
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
