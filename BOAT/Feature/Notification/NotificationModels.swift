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
    var isRead: Bool

    /// 목록 썸네일용 에셋 — subCategory 기반 기기 이미지. Android DeviceImage.resolve(null, subCategory) 대응(category 미사용).
    /// 단, 상시 유도 알림(마케팅/등록·미사용·분석 리마인더)은 특정 영수증과 무관하므로
    /// 항상 대분류 "기타" 기본 이미지로 고정한다.
    var imageName: String {
        guard !NotificationRouter.shouldRouteHome(messageType: messageType, kind: kind) else {
            return DeviceCategory.other.imageName
        }
        return DeviceImage.assetName(category: nil, subCategory: subCategory)
    }

    /// 알림 시간 표시 정책(UX 확정본):
    /// 1분 미만="방금 전" / 1시간 미만="N분 전" / 24시간 미만="N시간 전" /
    /// 7일 미만="N일 전" / 7일 이상="yyyy.MM.dd"
    var displayTime: String {
        guard let createdAt else { return "" }
        // 서버-클라 시각차로 미래 시각처럼 계산되는 경우 0으로 clamp (Android coerceAtLeast(0) 대응).
        let seconds = max(0, Date().timeIntervalSince(createdAt))
        switch seconds {
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

    /// 상시 유도 알림 카드 전용 — 상대 시간 대신 항상 절대 날짜("yyyy. MM. dd")를 노출한다.
    var persistentDisplayDate: String {
        guard let createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd"
        return formatter.string(from: createdAt)
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
            messageType: messageType,
            isRead: readAt != nil
        )
    }

    /// 서버 UTC 시각 문자열 → Date. 소수초+Z / Z만 / 타임존 표기 없음 등 여러 포맷을
    /// ServerDate가 순서대로 시도해 파싱한다.
    private static func parseDate(_ iso: String?) -> Date? {
        ServerDate.parse(iso)
    }
}

private extension String {
    var nonBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}
