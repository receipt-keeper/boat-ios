//
//  User.swift
//  BOAT
//
//  앱 유저 데이터 — 프로필 + 알림/마케팅 설정 + 무료 분석 토큰.
//

import Foundation

struct User: Codable, Equatable {
    /// 이메일
    var email: String
    /// 이름
    var name: String
    /// 프로필 이미지 URL
    var profileImageUrl: String
    /// 알림 수신 설정. true면 푸시 알림을 받는다.
    var notificationEnabled: Bool
    /// 마케팅 수신 동의 여부.
    var marketingConsent: Bool
    /// 남은 무료 분석 토큰 수.
    var freeAnalysisTokensRemaining: Int

    static let empty = User(
        email: "",
        name: "",
        profileImageUrl: "",
        notificationEnabled: true,
        marketingConsent: false,
        freeAnalysisTokensRemaining: 0
    )
}
