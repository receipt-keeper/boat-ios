//
//  NotificationModels.swift
//  BOAT
//
//  인앱 알림 목록 모델. GET /api/v1/notifications 응답 + 화면 표시 모델.
//  Android NotificationDto / AppNotification 대응.
//

import Foundation

// MARK: - 서버 응답

struct NotificationListData: Decodable {
    let notifications: [NotificationDto]
}

struct NotificationDto: Decodable {
    let notificationId: String
    let messageType: String?
    let kind: String?
    let title: String?
    let message: String?
    let resourceType: String?
    let resourceId: String?
    let metadata: [String: String]?
    let createdAt: String?      // ISO8601 "yyyy-MM-dd'T'HH:mm:ss"
    let readAt: String?         // 읽음 처리 시각 (nil이면 미읽음)
}

// MARK: - 화면 표시 모델

struct AppNotification: Identifiable, Hashable {
    let id: String
    let productName: String
    let message: String
    let createdAt: Date?
    let subCategory: String?
    let resourceType: String?
    let resourceId: String?
    let kind: String?
    let messageType: String?

    /// 목록 썸네일용 에셋 — subCategory 기반 기기 이미지. Android DeviceImage.resolve(null, subCategory) 대응(category 미사용).
    var imageName: String {
        DeviceImage.assetName(category: nil, subCategory: subCategory)
    }

    /// 알림 시간 표시 정책(UX 확정본):
    /// 1분 미만="방금 전" / 1시간 미만="N분 전" / 24시간 미만="N시간 전" /
    /// 7일 미만="N일 전" / 7일 이상="yyyy.MM.dd"
    var displayTime: String {
        guard let createdAt else { return "" }
        let seconds = Date().timeIntervalSince(createdAt)
        switch seconds {
        case ..<0:
            return Self.absoluteDate(createdAt) // 서버-클라 시각차로 미래 시각인 경우 폴백
        case ..<60:
            return String(localized: "notif.time.just_now")
        case ..<3600:
            return String(localized: "notif.time.minutes_ago \(Int(seconds / 60))")
        case ..<86400:
            return String(localized: "notif.time.hours_ago \(Int(seconds / 3600))")
        case ..<(86400 * 7):
            return String(localized: "notif.time.days_ago \(Int(seconds / 86400))")
        default:
            return Self.absoluteDate(createdAt)
        }
    }

    private static func absoluteDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

extension NotificationDto {
    func toAppNotification() -> AppNotification {
        AppNotification(
            id: notificationId,
            productName: metadata?["productName"]?.nonBlank
                ?? title?.nonBlank
                ?? String(localized: "notif.fallback_title"),
            message: message ?? "",
            createdAt: Self.parseDate(createdAt),
            subCategory: metadata?["subCategory"],
            resourceType: resourceType,
            resourceId: resourceId,
            kind: kind,
            messageType: messageType
        )
    }

    /// "2026-06-15T12:00:00" (또는 타임존 포함 ISO8601) → Date.
    /// 서버 시각은 UTC 기준이므로, 타임존 표기가 없는 응답도 UTC로 파싱해야 한다.
    private static func parseDate(_ iso: String?) -> Date? {
        guard let iso, !iso.isEmpty else { return nil }
        if let date = ISO8601DateFormatter().date(from: iso) { return date }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: iso)
    }
}

private extension String {
    var nonBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}
