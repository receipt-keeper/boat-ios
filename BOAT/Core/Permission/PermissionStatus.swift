//
//  PermissionStatus.swift
//  BOAT
//
//  사진/알림 등 시스템 권한의 현재 상태를 앱 공통 표현으로 단순화합니다.
//  iOS의 PHAuthorizationStatus, UNAuthorizationStatus 등 각기 다른 enum을
//  이 하나의 타입으로 매핑해 UI 분기를 일원화합니다.
//

import Foundation

enum PermissionStatus {
    /// 아직 한 번도 묻지 않음 → 시스템 다이얼로그 요청 가능
    case notDetermined
    /// 허용됨 (사진의 limited 포함)
    case granted
    /// 거부됨 → 다이얼로그 재요청 불가, 설정 앱으로 유도해야 함
    case denied

    /// 시스템 권한 다이얼로그를 띄울 수 있는 상태인지 여부
    var canRequest: Bool { self == .notDetermined }

    /// 설정 앱으로 보내야 하는 상태인지 여부
    var needsSettings: Bool { self == .denied }
}
