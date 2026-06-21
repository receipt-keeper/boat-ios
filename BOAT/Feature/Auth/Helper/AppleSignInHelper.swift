//
//  AppleSignInHelper.swift
//  BOAT
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import UIKit

final class AppleSignInHelper: NSObject {

    private(set) var currentNonce: String?

    typealias SignInResult = Result<(AuthCredential, SocialUserInfo), Error>

    private var signInCompletion: ((SignInResult) -> Void)?
    private var authController: ASAuthorizationController?

    // MARK: - 프로그래밍 방식 로그인 (커스텀 버튼 연동)

    /// 커스텀 버튼에서 호출 — ASAuthorizationController로 Apple 로그인 플로우 시작
    func startSignIn(completion: @escaping (SignInResult) -> Void) {
        signInCompletion = completion

        let request = ASAuthorizationAppleIDProvider().createRequest()
        prepareRequest(request)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        authController = controller
        controller.performRequests()
    }

    private func finish(_ result: SignInResult) {
        let completion = signInCompletion
        signInCompletion = nil
        authController = nil
        completion?(result)
    }

    // MARK: - 요청 구성 (nonce)

    /// request에 scope + nonce 설정
    private func prepareRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// ASAuthorization 결과에서 Firebase credential + 유저 정보(email/name) 추출
    private func process(
        _ result: Result<ASAuthorization, Error>,
        completion: @escaping (Result<(AuthCredential, SocialUserInfo), Error>) -> Void
    ) {
        switch result {
        case .failure(let error):
            completion(.failure(error))

        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                completion(.failure(NSError(
                    domain: "AppleSignIn",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: String(localized: "error.auth.apple_token_missing")]
                )))
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            // 이름: Apple은 최초 로그인 시에만 제공
            let name: String? = appleIDCredential.fullName.flatMap {
                let formatter = PersonNameComponentsFormatter()
                let formatted = formatter.string(from: $0)
                return formatted.isEmpty ? nil : formatted
            }

            let userInfo = SocialUserInfo(
                email: appleIDCredential.email,
                name: name,
                provider: .apple
            )

            completion(.success((credential, userInfo)))
        }
    }

    // MARK: - Nonce

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInHelper: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        process(.success(authorization)) { [weak self] result in
            self?.finish(result)
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        finish(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        return scene?.keyWindow ?? ASPresentationAnchor()
    }
}
