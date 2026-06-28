//
//  NotificationStore.swift
//  BOAT
//
//  앱 내 수신된 푸시 알림 목록을 로컬(UserDefaults)에 저장·관리하는 스토어.
//  푸시 수신 시 add(_:)로 적재, NotificationListView에서 열람.
//

import Foundation

struct NotificationItem: Identifiable, Codable {
    let id: String
    let productName: String
    let category: DeviceCategory
    let receivedAt: Date
    let message: String
    let dDay: Int
    var isRead: Bool

    init(
        id: String = UUID().uuidString,
        productName: String,
        category: DeviceCategory,
        receivedAt: Date = Date(),
        message: String,
        dDay: Int,
        isRead: Bool = false
    ) {
        self.id = id
        self.productName = productName
        self.category = category
        self.receivedAt = receivedAt
        self.message = message
        self.dDay = dDay
        self.isRead = isRead
    }
}

@Observable
final class NotificationStore {
    static let shared = NotificationStore()

    private(set) var items: [NotificationItem] = []

    private let defaultsKey = "boat.notifications"

    private init() { load() }

    var unreadCount: Int { items.filter { !$0.isRead }.count }

    func add(_ item: NotificationItem) {
        items.insert(item, at: 0) // 최신순
        save()
    }

    func markAllRead() {
        guard items.contains(where: { !$0.isRead }) else { return }
        for i in items.indices { items[i].isRead = true }
        save()
    }

    func remove(id: String) {
        items.removeAll { $0.id == id }
        save()
    }

    func clear() {
        items = []
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([NotificationItem].self, from: data)
        else { return }
        items = decoded
    }
}

// MARK: - Mock

extension NotificationItem {
    private static func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }

    static let mocks: [NotificationItem] = [
        NotificationItem(
            productName: "IPad Pro 13",
            category: .it,
            receivedAt: date(daysAgo: 0),
            message: "무상 AS 7일 남았어요! 일주일 뒤에는 무상 서비스 혜택이 종료됩니다.",
            dDay: 7,
            isRead: false
        ),
        NotificationItem(
            productName: "IPad Pro 13",
            category: .it,
            receivedAt: date(daysAgo: 0),
            message: "무상 AS 14일 남았어요! 기간이 지나기 전 영수증을 확인해보세요.",
            dDay: 14,
            isRead: false
        ),
        NotificationItem(
            productName: "IPad Pro 13",
            category: .it,
            receivedAt: date(daysAgo: 1),
            message: "무상 AS 30일 남았어요! 만료 전 서비스 센터를 방문해보세요.",
            dDay: 30,
            isRead: true
        ),
        NotificationItem(
            productName: "IPad Pro 13",
            category: .it,
            receivedAt: date(daysAgo: 2),
            message: "무상 AS 오늘이 만료예요! 마지막 무상 혜택을 확인하세요.",
            dDay: 0,
            isRead: true
        ),
        NotificationItem(
            productName: "IPad Pro 13",
            category: .it,
            receivedAt: date(daysAgo: 3),
            message: "무상 AS 오늘이 만료예요! 마지막 무상 혜택을 확인하세요.",
            dDay: 0,
            isRead: true
        ),
    ]
}
