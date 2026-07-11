//
//  NotificationPermissionGate.swift
//  BOAT
//
//  로그인 후 화면(MainTabView) 최초 진입 시 1회 알림 활성화 상태를 확인해,
//  꺼져 있으면 권한 요청 또는 앱 알림 설정으로 유도한다. Android NotificationPermissionGate 대응
//  (Android는 매 포그라운드 복귀마다 재확인하지만, iOS는 App Store 심사 가이드(5.1.1) —
//  "권한은 필요한 맥락에서, 반복 자동 재요청 지양" — 를 고려해 세션당 1회로 완화했다).
//  화면을 렌더링하지 않고 효과 + (필요 시) 다이얼로그만 노출한다.
//

import SwiftUI

struct NotificationPermissionGate: View {

    @Environment(PermissionManager.self) private var permissions

    @State private var showPriming = false
    @State private var showSettingsDialog = false

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task { await check() }
            // 미결정 상태 → 시스템 다이얼로그 전에 목적을 먼저 설명 (App Store 심사 가이드 5.1.1 —
            // "왜 필요한지 맥락 없이 바로 시스템 권한을 띄우지 말 것")
            .boatDialog(
                isPresented: $showPriming,
                title: "permission.notif.title",
                message: "permission.notif.message",
                confirmText: "permission.notif.confirm",
                cancelText: "permission.notif.later",
                onConfirm: { Task { await requestAfterPriming() } }
            )
            .boatDialog(
                isPresented: $showSettingsDialog,
                title: "permission.notif.denied_title",
                message: "permission.notif.gate_message",
                confirmText: "permission.notif.gate_confirm",
                cancelText: "permission.notif.later",
                onConfirm: { permissions.openSettings() }
            )
    }

    /// 알림이 꺼져 있으면: 미결정 상태 → 사전 설명 다이얼로그 / 거부 상태 → 설정 유도 다이얼로그.
    /// MainTabView가 살아있는 동안(로그인 세션) 한 번만 호출된다.
    private func check() async {
        await permissions.refreshAll()
        switch permissions.notificationStatus {
        case .granted:
            break
        case .notDetermined:
            showPriming = true
        case .denied:
            showSettingsDialog = true
        }
    }

    /// 사전 설명 다이얼로그에서 "알림 받기" 확인 시에만 실제 시스템 권한 다이얼로그 노출
    private func requestAfterPriming() async {
        _ = await permissions.requestNotificationPermission()
        if permissions.notificationStatus == .denied {
            showSettingsDialog = true
        }
    }
}
