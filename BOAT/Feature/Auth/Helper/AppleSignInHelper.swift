//
//  AppleSignInHelper.swift
//  BOAT
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth

final class AppleSignInHelper: NSObject {

    private(set) var currentNonce: String?

    // MARK: - SignInWithAppleButton 연동

    /// SignInWithAppleButton request 클로저에서 호출 — nonce 설정
    func prepareRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// SignInWithAppleButton onCompletion 클로저에서 호출 — credential + 유저 정보 추출
    func process(
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
