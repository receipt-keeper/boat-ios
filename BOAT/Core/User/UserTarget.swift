//
//  UserTarget.swift
//  BOAT
//
//  Users 엔드포인트. Android UserApiService 대응.
//  getMe/updateMe 모두 Bearer 필요 (requiresAuth 기본 true → 401 자동 갱신 적용).
//

import Foundation
import Alamofire

enum UserTarget {
    /// 현재 로그인 사용자 정보 조회
    case getMe
    /// 내 정보 부분 수정 (전달한 필드만 변경, 미전달 필드는 기존 값 유지)
    case updateMe(notificationEnabled: Bool?, marketingConsent: Bool?)
}

extension UserTarget: TargetType {

    var path: String {
        switch self {
        case .getMe, .updateMe: return "/api/v1/users/me"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getMe:    return .get
        case .updateMe: return .patch
        }
    }

    var task: RequestTask {
        switch self {
        case .getMe:
            return .plain
        case let .updateMe(notificationEnabled, marketingConsent):
            // nil 필드는 본문에서 제외 → 서버에서 "미전달 → 기존 값 유지"
            var body: [String: Any] = [:]
            if let notificationEnabled { body["notificationEnabled"] = notificationEnabled }
            if let marketingConsent { body["marketingConsent"] = marketingConsent }
            return .body(body)
        }
    }
}
