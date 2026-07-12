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

    /// refresh() 세대 토큰 — 홈/마이 등 여러 화면에서 거의 동시에 refresh()를 호출할 수 있는데,
    /// 먼저 시작된 호출이 네트워크 지연으로 더 나중에 끝나면 최신 결과를 오래된 값으로 덮어써
    /// 방금 읽음 처리한 알림의 Red Dot이 다시 켜지는 것처럼 보일 수 있다. 가장 최근에 시작된
    /// 호출의 결과만 반영되도록 막는다.
    private var generation = 0

    /// 미읽음 알림을 조회해 Red Dot 표시 여부를 갱신. (홈/목록/마이 진입·앱 복귀 시 호출)
    func refresh() async {
        generation += 1
        let token = generation
        guard let unread = try? await NotificationRepository.shared.fetchUnread() else { return }
        guard token == generation else { return } // 그사이 더 최신 refresh()가 시작됐으면 이 결과는 버림
        let seen = lastSeenAt
        hasUnread = unread.contains { ($0.createdAt ?? .distantPast) > seen }
    }

    /// 알림 목록 진입 시 호출 — 현재 시각을 "본 시각"으로 기록하고 Red Dot을 즉시 해제.
    func markSeen() {
        generation += 1 // 진행 중이던 refresh() 결과가 이후에 도착해 덮어쓰지 않도록 한다.
        lastSeenAt = Date()
        hasUnread = false
    }
}
