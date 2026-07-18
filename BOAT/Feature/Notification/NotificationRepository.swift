//
//  NotificationRepository.swift
//  BOAT
//
//  인앱 알림 목록 조회/읽음 처리. Android NotificationListViewModel의 데이터 접근부 대응.
//  정책: 알림 목록 화면에는 읽음/미읽음 모두 노출(읽은 알림은 화면에서 disabled 처리).
//  Red Dot 배지는 미읽음 알림 기준으로 판단.
//

import Foundation

@MainActor
final class NotificationRepository {
    static let shared = NotificationRepository()
    private init() {}

    /// GET /api/v1/notifications — 읽음/미읽음 모두 최신 표시 모델로 반환.
    func fetchAll() async throws -> [AppNotification] {
        let data: NotificationListData = try await APIClient.shared.request(NotificationTarget.list)
        return data.notifications.map { $0.toAppNotification() }
    }

    /// GET /api/v1/notifications — 미읽음 알림만 최신 표시 모델로 반환. (Red Dot 배지 판단용)
    func fetchUnread() async throws -> [AppNotification] {
        let data: NotificationListData = try await APIClient.shared.request(NotificationTarget.list)
        return data.notifications
            .filter { $0.readAt == nil }
            .map { $0.toAppNotification() }
    }

    /// PATCH /api/v1/notifications/{id} — 단건 읽음 처리. best-effort.
    func markRead(id: String) async {
        try? await APIClient.shared.requestVoid(NotificationTarget.markRead(id: id))
    }

    /// DELETE /api/v1/notifications/{id} — 단건 삭제. 성공/실패를 호출부가 알아야 하므로 throws.
    func delete(id: String) async throws {
        try await APIClient.shared.requestVoid(NotificationTarget.delete(id: id))
    }
}
