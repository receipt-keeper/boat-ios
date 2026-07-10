//
//  NotificationBadgeStore.swift
//  BOAT
//
//  공통 헤더 종 아이콘의 미읽음 표시(Red Dot) 상태. Android NotificationBadgeViewModel 대응.
//  - refresh(): 미읽음 알림 중 "마지막으로 알림 목록을 본 시각(lastSeenAt)" 이후 생성분이 있으면 Red Dot 표시.
//  - markSeen(): 알림 목록에 진입하면 호출 — 실제 개별 알림을 탭하지 않았어도 Red Dot을 즉시 해제한다.
//    (서버에 mark-all-read 엔드포인트가 없고, 목록은 미읽음 인박스 모델이라 "본 시각" 기준으로 처리)
//

import Foundation

@MainActor
@Observable
final class NotificationBadgeStore {
    static let shared = NotificationBadgeStore()
    private init() {}

    private let seenKey = "boat.notification.lastSeenAt"

    /// 헤더 종 아이콘에 Red Dot을 띄울지 여부.
    private(set) var hasUnread = false

    /// 마지막으로 알림 목록을 본 시각. 이 시각 이후에 생성된 미읽음 알림이 있으면 Red Dot을 띄운다.
    private var lastSeenAt: Date {
        get { Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: seenKey)) }
        set { UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: seenKey) }
    }

    /// 미읽음 알림을 조회해 Red Dot 표시 여부를 갱신. (홈/목록/마이 진입·앱 복귀 시 호출)
    func refresh() async {
        guard let unread = try? await NotificationRepository.shared.fetchUnread() else { return }
        let seen = lastSeenAt
        hasUnread = unread.contains { ($0.createdAt ?? .distantPast) > seen }
    }

    /// 알림 목록 진입 시 호출 — 현재 시각을 "본 시각"으로 기록하고 Red Dot을 즉시 해제.
    func markSeen() {
        lastSeenAt = Date()
        hasUnread = false
    }
}
