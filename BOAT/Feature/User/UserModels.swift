//
//  UserModels.swift
//  BOAT
//
//  Users API DTO. Android UserResponse 대응.
//  APIClient가 envelope(success/status/data)를 벗겨 data만 반환하므로
//  여기서는 data 페이로드 타입만 정의한다.
//  알림/마케팅 설정: NotificationSettingsRepository
//  크레딧(무료 분석 토큰): CreditRepository
//

import Foundation

/// GET /api/v1/users/me 의 data
struct UserData: Decodable {
    let email: String?
    let name: String?
    let nickname: String?
    let profileImageUrl: String?

    func toUser() -> User {
        User(
            email: email ?? "",
            name: name ?? "",
            nickname: nickname ?? "",
            profileImageUrl: profileImageUrl ?? ""
        )
    }
}
