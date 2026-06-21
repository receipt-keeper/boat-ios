//
//  AuthTarget.swift
//  BOAT
//
//  인증 관련 엔드포인트. Android AuthApiService에 대응.
//

import Foundation
import Alamofire

enum AuthTarget {
    /// 가입 겸 로그인 — Firebase ID 토큰 + 약관 동의 정보 전송
    case login(
        idToken: String,
        termsVersion: String,
        privacyVersion: String,
        termsAccepted: Bool,
        privacyAccepted: Bool,
        marketingConsent: Bool
    )
}

extension AuthTarget: TargetType {

    var path: String {
        switch self {
        case .login: return "/api/v1/auth/login"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login: return .post
        }
    }

    var task: RequestTask {
        switch self {
        case let .login(idToken, termsVersion, privacyVersion, termsAccepted, privacyAccepted, marketingConsent):
            return .body([
                "idToken": idToken,
                "termsVersion": termsVersion,
                "privacyVersion": privacyVersion,
                "termsAccepted": termsAccepted,
                "privacyAccepted": privacyAccepted,
                "marketingConsent": marketingConsent
            ])
        }
    }
}
