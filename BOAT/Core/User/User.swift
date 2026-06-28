//
//  User.swift
//  BOAT
//
//  앱 유저 데이터 — 프로필 + 무료 분석 토큰.
//  알림/마케팅 설정은 /api/v1/notifications/settings 로 분리됨.
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
    /// 남은 무료 분석 토큰 수.
    var freeAnalysisTokensRemaining: Int

    /// 표시용 이름 — 닉네임 우선, 없으면 이름
    var displayName: String {
        nickname.isEmpty ? name : nickname
    }

    static let empty = User(
        email: "",
        name: "",
        nickname: "",
        profileImageUrl: "",
        freeAnalysisTokensRemaining: 0
    )
}
