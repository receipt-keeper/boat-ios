//
//  NotificationListViewModel.swift
//  BOAT
//
//  알림 목록 상태 관리. 서버에서 미읽음 알림을 불러오고, 카드 탭 시 낙관적으로 제거 + 읽음 처리.
//  Android NotificationListViewModel 대응.
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
        notifications = (try? await repository.fetchUnread()) ?? []
        isLoading = false
        didLoadOnce = true
    }

    /// 카드 탭 — 목록에서 즉시 제거(낙관적) 후 서버 읽음 처리.
    /// 실패해도 서버가 읽음 처리 안 됐을 뿐, 다음 조회 때 다시 나타난다.
    func markReadAndRemove(_ item: AppNotification) {
        notifications.removeAll { $0.id == item.id }
        Task { await repository.markRead(id: item.id) }
    }
}
