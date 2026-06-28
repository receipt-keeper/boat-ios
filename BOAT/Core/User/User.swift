//
//  User.swift
//  BOAT
//
//  앱 유저 데이터 — 프로필 정보만 포함.
//  알림/마케팅 설정: /api/v1/notifications/settings
//  크레딧(무료 분석 토큰): /api/v1/credits
//

import Foundation

struct User: Codable, Equatable {
    /// 이메일
    var email: String
    /// 이름
    var name: String
    /// 닉네임
    var nickname: String
    /// 프로필 이미지 URL
    var profileImageUrl: String

    /// 표시용 이름 — 닉네임 우선, 없으면 이름
    var displayName: String {
        nickname.isEmpty ? name : nickname
    }

    static let empty = User(
        email: "",
        name: "",
        nickname: "",
        profileImageUrl: ""
    )
}
