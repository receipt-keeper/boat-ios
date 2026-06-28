//
//  UserTarget.swift
//  BOAT
//
//  Users 엔드포인트. Android UserApiService 대응.
//  getMe는 Bearer 필요 (requiresAuth 기본 true → 401 자동 갱신 적용).
//  알림/마케팅 설정 수정은 NotificationSettingsTarget 으로 분리됨.
//

import Foundation
import Alamofire

enum UserTarget {
    /// 현재 로그인 사용자 정보 조회
    case getMe
}

extension UserTarget: TargetType {

    var path: String { "/api/v1/users/me" }

    var method: HTTPMethod { .get }

    var task: RequestTask { .plain }
}
