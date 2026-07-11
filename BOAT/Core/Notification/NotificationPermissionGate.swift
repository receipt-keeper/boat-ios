//
//  NotificationPermissionGate.swift
//  BOAT
//
//  로그인 후 화면(MainTabView) 진입 시 + 포그라운드로 복귀할 때마다 알림 활성화 상태를
//  재확인해, 꺼져 있으면 사전 설명 후 권한 요청 또는 앱 알림 설정으로 유도한다.
//  (외부 설정 앱에서 사용자가 실수로 알림을 꺼도 다음에 앱을 열었을 때 바로 잡아낸다.)
//  Android NotificationPermissionGate(LifecycleResumeEffect로 매 resume마다 재확인)와 동일 패턴 —
//  실제 시스템 권한 다이얼로그는 OS가 최초 1회만 띄워주므로(재요청해도 그냥 현재 상태만 반환),
//  우리 쪽 안내 다이얼로그를 매번 다시 보여줘도 App Store 심사 가이드(5.1.1)에 어긋나지 않는다.
//  화면을 렌더링하지 않고 효과 + (필요 시) 다이얼로그만 노출한다.
//

import SwiftUI

struct NotificationPermissionGate: View {

    @Environment(PermissionManager.self) private var permissions
    @Environment(\.scenePhase) private var scenePhase

    @State private var showPriming = false
    @State private var showSettingsDialog = false

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task { await check() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { Task { await check() } }
            }
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
    /// 화면 최초 진입 + 매 포그라운드 복귀마다 호출된다.
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
