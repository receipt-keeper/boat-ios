//
//  NotificationRepository.swift
//  BOAT
//
//  인앱 알림 목록 조회/읽음 처리. Android NotificationListViewModel의 데이터 접근부 대응.
//  정책: 아직 읽지 않은(readAt == nil) 알림만 노출. 읽으면 목록에서 제거.
//

import Foundation

@MainActor
final class NotificationRepository {
    static let shared = NotificationRepository()
    private init() {}

    /// GET /api/v1/notifications — 미읽음 알림만 최신 표시 모델로 반환.
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
}
