//
//  UserModels.swift
//  BOAT
//
//  Users API DTO. Android UserResponse/UpdateMeModels 대응.
//  APIClient가 envelope(success/status/data)를 벗겨 data만 반환하므로
//  여기서는 data 페이로드 타입만 정의한다.
//

import Foundation

/// GET /api/v1/users/me 의 data
struct UserData: Decodable {
    let email: String?
    let name: String?
    let nickname: String?
    let profileImageUrl: String?
    let notificationEnabled: Bool?
    let marketingConsent: Bool?
    let freeAnalysisTokensRemaining: Int?

    /// 서버 DTO → 앱 도메인 모델 (null은 빈 값/기본값으로)
    func toUser() -> User {
        User(
            email: email ?? "",
            name: name ?? "",
            nickname: nickname ?? "",
            profileImageUrl: profileImageUrl ?? "",
            notificationEnabled: notificationEnabled ?? false,
            marketingConsent: marketingConsent ?? false,
            freeAnalysisTokensRemaining: freeAnalysisTokensRemaining ?? 0
        )
    }
}

/// PATCH /api/v1/users/me 의 data (변경 결과)
struct UpdateMeData: Decodable {
    let notificationEnabled: Bool?
    let marketingConsent: Bool?
}
