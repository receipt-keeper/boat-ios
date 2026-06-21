//
//  AuthModels.swift
//  BOAT
//
//  Android LoginResponse(LoginTokenData)에 대응하는 인증 API 모델.
//

import Foundation

/// POST /api/v1/auth/login 응답의 data 페이로드
struct LoginTokenData: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
}
