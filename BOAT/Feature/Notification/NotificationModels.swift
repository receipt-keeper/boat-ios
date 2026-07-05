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
    let date: String            // "yyyy.MM.dd"
    let subCategory: String?
    let resourceType: String?
    let resourceId: String?
    let kind: String?

    /// 목록 썸네일용 에셋 — subCategory 기반 기기 이미지. Android DeviceImage.resolve(null, subCategory) 대응(category 미사용).
    var imageName: String {
        DeviceImage.assetName(category: nil, subCategory: subCategory)
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
            date: Self.displayDate(createdAt),
            subCategory: metadata?["subCategory"],
            resourceType: resourceType,
            resourceId: resourceId,
            kind: kind
        )
    }

    /// "2026-06-15T12:00:00" → "2026.06.15"
    private static func displayDate(_ iso: String?) -> String {
        guard let iso, !iso.isEmpty else { return "" }
        let datePart = iso.split(separator: "T").first.map(String.init) ?? iso
        return datePart.replacingOccurrences(of: "-", with: ".")
    }
}

private extension String {
    var nonBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}
