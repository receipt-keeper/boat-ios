//
//  NotificationPermissionGate.swift
//  BOAT
//
//  "가입/로그인을 완료한 뒤 앱을 완전히 껐다가 재실행했을 때"만 알림 권한 다이얼로그를 띄운다.
//
//  - 앱을 처음 켜자마자(또는 이번 프로세스 안에서 방금 로그인/회원가입을 마친 직후)는 노출하지 않는다
//    → AppLaunchState.wasLoggedInAtProcessStart가 true인, 즉 "이미 로그인된 채로 시작된"
//      콜드 스타트에서만 평가한다.
//  - 평가는 콜드 스타트당 1회뿐(기존의 "포그라운드 복귀마다 재확인" 동작 제거).
//  - "나중에"를 누르면 30일간 다시 노출하지 않되, 알림 권한 자체는 건드리지 않는다.
//  - 다이얼로그에서 알림 권한을 허용하면 서비스의 만료 예정 알림(pushEnabled) 설정도 true로 동기화한다.
//
//  화면을 렌더링하지 않고 효과 + (필요 시) 다이얼로그만 노출한다.
//

import SwiftUI

struct NotificationPermissionGate: View {

    @Environment(PermissionManager.self) private var permissions

    @State private var showPriming = false
    @State private var showSettingsDialog = false

    private static let nextDisplayAtKey = "boat.notifGate.nextDisplayAt"
    private static let snoozeDays = 30

    /// 이번 프로세스에서 이미 한 번 평가했는지 — .task가 재실행되더라도 중복 평가를 막는다.
    @State private var hasCheckedThisProcess = false

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task {
                guard !hasCheckedThisProcess else { return }
                hasCheckedThisProcess = true
                await check()
            }
            // 미결정 상태 → 시스템 다이얼로그 전에 목적을 먼저 설명 (App Store 심사 가이드 5.1.1 —
            // "왜 필요한지 맥락 없이 바로 시스템 권한을 띄우지 말 것")
            .boatDialog(
                isPresented: $showPriming,
                title: "permission.notif.title",
                message: "permission.notif.message",
                confirmText: "permission.notif.confirm",
                cancelText: "permission.notif.later",
                onConfirm: { Task { await requestAfterPriming() } },
                onCancel: { deferGate() }
            )
            .boatDialog(
                isPresented: $showSettingsDialog,
                title: "permission.notif.denied_title",
                message: "permission.notif.gate_message",
                confirmText: "permission.notif.gate_confirm",
                cancelText: "permission.notif.later",
                onConfirm: { permissions.openSettings() },
                onCancel: { deferGate() }
            )
    }

    /// 알림이 꺼져 있으면: 미결정 상태 → 사전 설명 다이얼로그 / 거부 상태 → 설정 유도 다이얼로그.
    /// 이번 프로세스가 "이미 로그인된 채로 시작"됐고, 30일 스누즈가 끝났을 때만 평가한다.
    private func check() async {
        guard AppLaunchState.wasLoggedInAtProcessStart else { return }
        guard Date().timeIntervalSince1970 >= UserDefaults.standard.double(forKey: Self.nextDisplayAtKey) else { return }

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
        let status = await permissions.requestNotificationPermission()
        if status == .granted {
            // 다이얼로그에서 알림 권한을 허용한 경우 → 만료 예정 알림 설정도 함께 true로 동기화
            try? await NotificationSettingsRepository.shared.updateSettings(pushEnabled: true)
        } else if status == .denied {
            showSettingsDialog = true
        }
    }

    /// "나중에" — 다이얼로그만 닫고 알림 권한은 건드리지 않되, 30일간 다시 노출하지 않는다.
    private func deferGate() {
        let next = Date().addingTimeInterval(TimeInterval(Self.snoozeDays * 86400))
        UserDefaults.standard.set(next.timeIntervalSince1970, forKey: Self.nextDisplayAtKey)
    }
}
