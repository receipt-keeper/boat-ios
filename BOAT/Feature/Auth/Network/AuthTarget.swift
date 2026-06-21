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
    /// 로그아웃 — refreshToken 세션 revoke (204)
    case logout(refreshToken: String)
    /// AccessToken 재발급 — refreshToken 1회용 회전
    case refresh(refreshToken: String)
}

extension AuthTarget: TargetType {

    var path: String {
        switch self {
        case .login:   return "/api/v1/auth/login"
        case .logout:  return "/api/v1/auth/logout"
        case .refresh: return "/api/v1/auth/refresh"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .logout, .refresh: return .post
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
        case let .logout(refreshToken):
            return .body(["refreshToken": refreshToken])
        case let .refresh(refreshToken):
            return .body(["refreshToken": refreshToken])
        }
    }

    // 인증 헤더/자동 갱신 대상이 아님 (토큰을 body로 직접 전달)
    var requiresAuth: Bool { false }
}
