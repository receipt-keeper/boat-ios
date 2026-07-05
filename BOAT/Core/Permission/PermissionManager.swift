//
//  PermissionManager.swift
//  BOAT
//
//  카메라 / 알림 권한의 상태를 관리합니다.
//
//  설계 원칙
//  --------
//  - "확인(refresh)"과 "요청(request)"을 분리합니다.
//    · 시스템 권한 다이얼로그는 앱 생애 단 한 번만 노출되므로, 앱 시작·포그라운드 복귀
//      시점에는 '요청'이 아니라 '상태 확인'만 합니다. (실제 요청은 기능 진입 시점)
//    · 사용자가 백그라운드에서 설정을 바꿨을 수 있으므로, 포그라운드 복귀 시
//      refreshAll()로 최신 상태를 다시 읽어 UI에 반영합니다.
//  - 거부(denied) 상태에서는 재요청이 불가능하므로 openSettings()로 유도합니다.
//
//  ※ 사진(갤러리): SwiftUI PhotosPicker(PHPickerViewController)만 사용하면 권한이 전혀
//    필요 없습니다(프로세스 외부에서 고른 사진만 전달). 그래서 이 매니저는 사진 권한을
//    다루지 않습니다.
//

import Foundation
import AVFoundation
import UserNotifications
import UIKit

@Observable
@MainActor
final class PermissionManager {

    private(set) var cameraStatus: PermissionStatus = .notDetermined
    private(set) var notificationStatus: PermissionStatus = .notDetermined

    // MARK: - 상태 확인 (앱 시작 / 포그라운드 복귀마다 호출 — 다이얼로그 안 뜸)

    /// 카메라·알림 권한 상태를 한 번에 다시 읽어 옵니다.
    func refreshAll() async {
        cameraStatus = currentCameraStatus()
        notificationStatus = await currentNotificationStatus()
    }

    private func currentCameraStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:       return .notDetermined
        case .authorized:          return .granted
        case .denied, .restricted: return .denied
        @unknown default:          return .denied
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

    // MARK: - 권한 요청 (notDetermined일 때 1회, 기능 진입 시점)

    /// 카메라 권한을 요청합니다. 이미 결정된 상태면 다이얼로그 없이 현재 값만 갱신됩니다.
    @discardableResult
    func requestCameraPermission() async -> PermissionStatus {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraStatus = granted ? .granted : currentCameraStatus()
        return cameraStatus
    }

    /// 알림 권한을 요청합니다.
    @discardableResult
    func requestNotificationPermission() async -> PermissionStatus {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        // 요청 직후 정확한 상태를 다시 읽어 반영 (provisional 등 케이스 대응)
        notificationStatus = await currentNotificationStatus()
        return notificationStatus
    }

    // MARK: - 설정 앱으로 이동 (denied 상태 유도)

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
