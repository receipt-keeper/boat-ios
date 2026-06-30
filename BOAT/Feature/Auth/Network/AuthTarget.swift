//
//  AuthTarget.swift
//  BOAT
//
//  인증 관련 엔드포인트. Android AuthApiService에 대응.
//  login — 기존 회원 로그인 (idToken만 전송, 404이면 미가입)
//  signup — 신규 회원가입 (idToken + 약관 동의 정보)
//

import Foundation
import Alamofire

enum AuthTarget {
    /// 기존 회원 로그인 — Firebase ID 토큰만 전송 (404 → 미가입 → signup 화면)
    case login(idToken: String)
    /// 신규 회원가입 — Firebase ID 토큰 + 약관 동의 정보
    case signup(
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
    /// 회원 탈퇴 — 서버 계정 삭제 (204), Bearer 필요
    case deleteAccount
}

extension AuthTarget: TargetType {

    var path: String {
        switch self {
        case .login:         return "/api/v1/auth/login"
        case .signup:        return "/api/v1/auth/signup"
        case .logout:        return "/api/v1/auth/logout"
        case .refresh:       return "/api/v1/auth/refresh"
        case .deleteAccount: return "/api/v1/auth/me"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .signup, .logout, .refresh: return .post
        case .deleteAccount:                     return .delete
        }
    }

    var task: RequestTask {
        switch self {
        case let .login(idToken):
            return .body(["idToken": idToken])

        case let .signup(idToken, termsVersion, privacyVersion, termsAccepted, privacyAccepted, marketingConsent):
            return .body([
                "idToken":           idToken,
                "termsVersion":      termsVersion,
                "privacyVersion":    privacyVersion,
                "termsAccepted":     termsAccepted,
                "privacyAccepted":   privacyAccepted,
                "marketingConsent":  marketingConsent
            ])

        case let .logout(refreshToken):
            return .body(["refreshToken": refreshToken])

        case let .refresh(refreshToken):
            return .body(["refreshToken": refreshToken])

        case .deleteAccount:
            return .plain
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .logout, .refresh: return false
        case .deleteAccount:                     return true
        }
    }
}
