//
//  NotificationSettingsRepository.swift
//  BOAT
//
//  알림 설정 데이터 접근. GET /api/v1/notifications/settings 조회 +
//  PATCH /api/v1/notifications/settings 부분 수정.
//  낙관적 UI 업데이트는 View에서 직접 처리하고 서버 확정값을 반환한다.
//

import Foundation

/// GET·PATCH /api/v1/notifications/settings 의 data 페이로드
struct NotificationSettings: Decodable {
    let pushEnabled: Bool
    let marketingConsent: Bool
}

@MainActor
final class NotificationSettingsRepository {
    static let shared = NotificationSettingsRepository()
    private init() {}

    /// GET /api/v1/notifications/settings
    func fetchSettings() async throws -> NotificationSettings {
        try await APIClient.shared.request(NotificationSettingsTarget.getSettings)
    }

    /// PATCH /api/v1/notifications/settings — 보낸 필드만 변경, 나머지 유지
    @discardableResult
    func updateSettings(pushEnabled: Bool? = nil, marketingConsent: Bool? = nil) async throws -> NotificationSettings {
        try await APIClient.shared.request(
            NotificationSettingsTarget.updateSettings(
                pushEnabled: pushEnabled,
                marketingConsent: marketingConsent
            )
        )
    }
}
