//
//  NotificationSettingsTarget.swift
//  BOAT
//
//  알림 설정 엔드포인트. GET/PATCH /api/v1/notifications/settings
//  users/me에서 분리된 별도 API. 푸시/마케팅 수신 여부 조회·수정.
//

import Foundation
import Alamofire

enum NotificationSettingsTarget {
    case getSettings
    case updateSettings(pushEnabled: Bool?, marketingConsent: Bool?)
}

extension NotificationSettingsTarget: TargetType {

    var path: String { "/api/v1/notifications/settings" }

    var method: HTTPMethod {
        switch self {
        case .getSettings:    return .get
        case .updateSettings: return .patch
        }
    }

    var task: RequestTask {
        switch self {
        case .getSettings:
            return .plain
        case let .updateSettings(pushEnabled, marketingConsent):
            var body: [String: Any] = [:]
            if let pushEnabled    { body["pushEnabled"]      = pushEnabled }
            if let marketingConsent { body["marketingConsent"] = marketingConsent }
            return .body(body)
        }
    }
}
