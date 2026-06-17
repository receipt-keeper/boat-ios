//
//  PermissionManager.swift
//  BOAT
//
//  사진 라이브러리 / 알림 권한의 상태를 관리합니다.
//
//  설계 원칙
//  --------
//  - "확인(refresh)"과 "요청(request)"을 분리합니다.
//    · 권한 다이얼로그는 앱 생애 단 한 번만 노출되므로, 앱 시작·포그라운드 복귀
//      시점에 반복 호출해도 되는 건 '요청'이 아니라 '상태 확인'입니다.
//    · 사용자가 백그라운드에서 설정을 바꿨을 수 있으므로, 포그라운드 복귀 시
//      refresh()로 최신 상태를 다시 읽어 UI에 반영합니다.
//  - 거부(denied) 상태에서는 재요청이 불가능하므로 openSettings()로 유도합니다.
//
//  ※ 갤러리에서 이미지를 '고르기만' 한다면 SwiftUI PhotosPicker는 권한이 불필요합니다.
//    이 매니저의 photo 권한은 전체 라이브러리 직접 접근이 필요한 경우에만 사용하세요.
//

import Foundation
import Photos
import UserNotifications
import UIKit

@Observable
@MainActor
final class PermissionManager {

    private(set) var photoStatus: PermissionStatus = .notDetermined
    private(set) var notificationStatus: PermissionStatus = .notDetermined

    // MARK: - 상태 확인 (앱 시작 / 포그라운드 복귀마다 호출)

    /// 사진·알림 권한 상태를 한 번에 다시 읽어 옵니다.
    func refreshAll() async {
        photoStatus = currentPhotoStatus()
        notificationStatus = await currentNotificationStatus()
    }

    private func currentPhotoStatus() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:        return .notDetermined
        case .authorized, .limited: return .granted
        case .denied, .restricted:  return .denied
        @unknown default:           return .denied
        }
    }

    private func currentNotificationStatus() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:                          return .notDetermined
        case .authorized, .provisional, .ephemeral:   return .granted
        case .denied:                                 return .denied
        @unknown default:                             return .denied
        }
    }

    // MARK: - 권한 요청 (notDetermined일 때 1회, 보통 기능 진입 시점)

    /// 사진 라이브러리 권한을 요청합니다. 이미 결정된 상태면 다이얼로그 없이 현재 값만 갱신됩니다.
    @discardableResult
    func requestPhotoPermission() async -> PermissionStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photoStatus = {
            switch status {
            case .notDetermined:        return .notDetermined
            case .authorized, .limited: return .granted
            case .denied, .restricted:  return .denied
            @unknown default:           return .denied
            }
        }()
        return photoStatus
    }

    /// 알림 권한을 요청합니다.
    @discardableResult
    func requestNotificationPermission() async -> PermissionStatus {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        // 요청 직후 정확한 상태를 다시 읽어 반영 (provisional 등 케이스 대응)
        notificationStatus = await currentNotificationStatus()
        return granted ? .granted : notificationStatus
    }

    // MARK: - 설정 앱으로 이동 (denied 상태 유도)

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
