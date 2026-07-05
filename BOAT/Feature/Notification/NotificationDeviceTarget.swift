//
//  NotificationDeviceTarget.swift
//  BOAT
//
//  FCM 디바이스 등록/해제 엔드포인트. Android NotificationApiService.registerDevice/unregisterDevice 대응.
//  - PUT    /api/v1/notifications/devices        (FCM 토큰 멱등 upsert, 204)
//  - DELETE /api/v1/notifications/devices/{token} (해제, 204)
//

import Foundation
import Alamofire

enum NotificationDeviceTarget {
    case register(token: String)
    case unregister(token: String)
}

extension NotificationDeviceTarget: TargetType {

    var path: String {
        switch self {
        case .register:
            return "/api/v1/notifications/devices"
        case let .unregister(token):
            return "/api/v1/notifications/devices/\(token)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .register:   return .put
        case .unregister: return .delete
        }
    }

    var task: RequestTask {
        switch self {
        case let .register(token):
            return .body(["token": token, "platform": "ios"])
        case .unregister:
            return .plain
        }
    }
}
