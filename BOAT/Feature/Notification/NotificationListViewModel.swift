//
//  NotificationListViewModel.swift
//  BOAT
//
//  알림 목록 상태 관리. 서버에서 읽음/미읽음 알림을 모두 불러오고, 카드 탭 시 낙관적으로
//  읽음 처리(목록에서 제거하지 않고 disabled 표시로 전환). Android NotificationListViewModel 대응.
//

import SwiftUI

@MainActor
@Observable
final class NotificationListViewModel {

    private(set) var notifications: [AppNotification] = []
    private(set) var isLoading = true
    private(set) var didLoadOnce = false

    private let repository = NotificationRepository.shared

    func load() async {
        isLoading = true
        notifications = (try? await repository.fetchAll()) ?? []
        isLoading = false
        didLoadOnce = true
    }

    /// 카드 탭 — 목록에 남긴 채 읽음 상태로 낙관적 전환(disabled 표시) 후 서버 읽음 처리.
    /// 실패해도 화면상 읽음 표시만 유지되고, 다음 조회 때 서버 상태로 다시 맞춰진다.
    func markAsRead(_ item: AppNotification) {
        guard let index = notifications.firstIndex(where: { $0.id == item.id }) else { return }
        notifications[index].isRead = true
        Task { await repository.markRead(id: item.id) }
    }

    /// 케밥 → "삭제하기" — 삭제 API 호출 성공 후에만 목록을 다시 불러와 반영한다.
    func delete(_ item: AppNotification) async throws {
        try await repository.delete(id: item.id)
        await load()
    }
}
