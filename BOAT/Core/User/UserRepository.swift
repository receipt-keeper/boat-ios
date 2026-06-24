//
//  UserRepository.swift
//  BOAT
//
//  사용자 정보 데이터 접근. Android UserRepository 대응.
//  서버 조회/부분수정 + 로컬 캐시(UserStore) 동기화를 담당한다.
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

    /// 내 정보 부분 수정. 낙관적 로컬 반영 → 서버 PATCH → 서버 확정값 재동기화.
    func updateMe(notificationEnabled: Bool? = nil, marketingConsent: Bool? = nil) async throws {
        // 1) 낙관적 로컬 반영 (토글 즉시 반응)
        store.update { user in
            if let notificationEnabled { user.notificationEnabled = notificationEnabled }
            if let marketingConsent { user.marketingConsent = marketingConsent }
        }
        // 2) 서버 부분 수정
        let result: UpdateMeData = try await APIClient.shared.request(
            UserTarget.updateMe(notificationEnabled: notificationEnabled, marketingConsent: marketingConsent)
        )
        // 3) 서버가 확정한 값으로 재동기화
        store.update { user in
            if let n = result.notificationEnabled { user.notificationEnabled = n }
            if let m = result.marketingConsent { user.marketingConsent = m }
        }
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
