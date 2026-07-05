//
//  NotificationPermissionGate.swift
//  BOAT
//
//  로그인 후 화면(MainTabView) 진입/복귀마다 알림 활성화 상태를 확인해,
//  꺼져 있으면 권한 요청 또는 앱 알림 설정으로 유도한다. Android NotificationPermissionGate 대응.
//  화면을 렌더링하지 않고 효과 + (필요 시) 다이얼로그만 노출한다.
//

import SwiftUI

struct NotificationPermissionGate: View {

    @Environment(PermissionManager.self) private var permissions
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSettingsDialog = false

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task { await check() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await check() }
                }
            }
            .boatDialog(
                isPresented: $showSettingsDialog,
                title: "permission.notif.denied_title",
                message: "permission.notif.gate_message",
                confirmText: "permission.notif.gate_confirm",
                cancelText: "permission.notif.later",
                onConfirm: { permissions.openSettings() }
            )
    }

    /// 알림이 꺼져 있으면: 미결정 상태 → 시스템 권한 요청 / 거부 상태 → 설정 유도 다이얼로그.
    private func check() async {
        await permissions.refreshAll()
        switch permissions.notificationStatus {
        case .granted:
            break
        case .notDetermined:
            _ = await permissions.requestNotificationPermission()
            if permissions.notificationStatus == .denied {
                showSettingsDialog = true
            }
        case .denied:
            showSettingsDialog = true
        }
    }
}
