//
//  UserRepository.swift
//  BOAT
//
//  사용자 정보 데이터 접근. Android UserRepository 대응.
//  서버 조회/로컬 캐시(UserStore) 동기화를 담당한다.
//  알림/마케팅 설정 수정은 NotificationSettingsRepository 로 분리됨.
//

import Foundation

@MainActor
final class UserRepository {

    static let shared = UserRepository()
    private init() {}

    private let store = UserStore.shared

    /// 서버에서 내 정보 조회 후 로컬에 캐시. 성공 시 최신 User 반환.
    @discardableResult
    func refreshUser() async throws -> User {
        let data: UserData = try await APIClient.shared.request(UserTarget.getMe)
        let user = data.toUser()
        store.save(user)
        return user
    }

    /// 남은 무료 분석 토큰 수만 갱신 (로컬)
    func updateFreeAnalysisTokens(_ remaining: Int) {
        store.update { $0.freeAnalysisTokensRemaining = remaining }
    }

    /// 로그아웃/탈퇴 시 정리
    func clear() {
        store.clear()
    }
}
