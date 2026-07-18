//
//  NotificationTarget.swift
//  BOAT
//
//  인앱 알림 목록 엔드포인트. Android NotificationApiService 대응.
//  - GET    /api/v1/notifications              (알림 목록)
//  - PATCH  /api/v1/notifications/{id}          (단건 읽음 처리)
//  - DELETE /api/v1/notifications/{id}          (단건 삭제)
//

import Foundation
import Alamofire

enum NotificationTarget {
    case list
    case markRead(id: String)
    case delete(id: String)
}

extension NotificationTarget: TargetType {

    var path: String {
        switch self {
        case .list:
            return "/api/v1/notifications"
        case let .markRead(id):
            return "/api/v1/notifications/\(id)"
        case let .delete(id):
            return "/api/v1/notifications/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list:     return .get
        case .markRead: return .patch
        case .delete:   return .delete
        }
    }

    var task: RequestTask { .plain }
}
