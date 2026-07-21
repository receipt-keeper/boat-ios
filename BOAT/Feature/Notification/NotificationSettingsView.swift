//
//  NotificationSettingsView.swift
//  BOAT
//
//  알림 설정 화면. Android NotificationSettingsScreen/ViewModel 대응.
//  GET /api/v1/notifications/settings 로 초기값 로드.
//  토글 변경 → PATCH /api/v1/notifications/settings 반영.
//  실패 시 에러 토스트 + 이전 값으로 복구.
//

import SwiftUI

struct NotificationSettingsView: View {

    let onBack: () -> Void

    @Environment(PermissionManager.self) private var permissions

    @State private var pushEnabled = false
    @State private var marketingConsent = false
    @State private var toast = BoatToastState()
    // 알림 사전 설명(프리퍼미션) / 거부 시 설정 유도
    @State private var showNotifPriming = false
    @State private var showNotifDenied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar

            Spacer().frame(height: .spacing8)

            toggleRow(
                label: "notif.settings.alarm",
                isOn: pushEnabled,
                onChange: setPushEnabled
            )
            toggleRow(
                label: "notif.settings.marketing",
                isOn: marketingConsent,
                onChange: setMarketingConsent,
                bottomPadding: 4
            )

            Text("notif.settings.footnote")
                .font(.pretendard(.medium, size: 12))
                .foregroundStyle(Color.gray500)
                .lineSpacing(4)
                .padding(.horizontal, .spacing20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        .boatToastHost(toast)
        // 알림 사전 설명 → [알림 받기] 탭에서만 시스템 권한 요청 (1회성 프롬프트 보호)
        .boatDialog(
            isPresented: $showNotifPriming,
            title: "permission.notif.title",
            message: "permission.notif.message",
            confirmText: "permission.notif.confirm",
            cancelText: "permission.notif.later",
            onConfirm: { confirmNotifPriming() }
        )
        // OS 알림이 거부된 상태 → 설정 앱으로 유도
        .boatDialog(
            isPresented: $showNotifDenied,
            title: "permission.notif.denied_title",
            message: "permission.notif.denied_message",
            confirmText: "permission.open_settings",
            cancelText: "common.cancel",
            onConfirm: { permissions.openSettings() }
        )
        .task {
            if let settings = try? await NotificationSettingsRepository.shared.fetchSettings() {
                pushEnabled = settings.pushEnabled
                marketingConsent = settings.marketingConsent
            }
        }
    }

    // MARK: - 토글 동작 (낙관적 반영 → PATCH → 서버 확정 or 복구)

    private func setPushEnabled(_ enabled: Bool) {
        guard pushEnabled != enabled else { return }
        if enabled {
            // 켤 때는 OS 알림 권한을 먼저 확인/요청한 뒤 서버 설정을 반영
            Task { await gateNotificationPermission() }
        } else {
            applyPush(false)
        }
    }

    /// OS 알림 권한 상태에 따라 분기: 허용→서버 반영 / 미결정→사전 설명 / 거부→설정 유도
    private func gateNotificationPermission() async {
        await permissions.refreshAll()
        switch permissions.notificationStatus {
        case .granted:        applyPush(true)
        case .notDetermined:  showNotifPriming = true
        case .denied:         showNotifDenied = true
        }
    }

    /// 사전 설명 [알림 받기] — 여기서만 실제 시스템 권한 다이얼로그 노출
    private func confirmNotifPriming() {
        Task {
            let status = await permissions.requestNotificationPermission()
            if status == .granted {
                applyPush(true)
            } else {
                // 거부 시 토글은 off로 유지 (알림이 오지 않으므로)
                showNotifDenied = true
            }
        }
    }

    /// 서버 push 설정 반영 (낙관적 업데이트 → 실패 시 복구)
    private func applyPush(_ enabled: Bool) {
        let previous = pushEnabled
        pushEnabled = enabled
        Task {
            do {
                let result = try await NotificationSettingsRepository.shared.updateSettings(pushEnabled: enabled)
                pushEnabled = result.pushEnabled
                showPushConsentToast(enabled: result.pushEnabled)
            } catch {
                pushEnabled = previous
                toast.showError((error as? LocalizedError)?.errorDescription ?? "")
            }
        }
    }

    private func setMarketingConsent(_ consent: Bool) {
        guard marketingConsent != consent else { return }
        let previous = marketingConsent
        marketingConsent = consent
        Task {
            do {
                let result = try await NotificationSettingsRepository.shared.updateSettings(marketingConsent: consent)
                marketingConsent = result.marketingConsent
                showMarketingConsentToast(enabled: result.marketingConsent)
            } catch {
                marketingConsent = previous
                toast.showError((error as? LocalizedError)?.errorDescription ?? "")
            }
        }
    }

    /// 알림 수신 토글 on/off 안내 토스트 (off일 땐 다시 켜도록 유도하는 안내문구).
    private func showPushConsentToast(enabled: Bool) {
        if enabled {
            toast.show(String(localized: "notif.settings.consent_granted"), type: .info)
        } else {
            toast.show(String(localized: "notif.settings.consent_withdrawn"), type: .info)
        }
    }

    /// 마케팅 정보 수신 동의 토글 on/off 안내 토스트.
    private func showMarketingConsentToast(enabled: Bool) {
        if enabled {
            toast.show(String(localized: "notif.settings.consent_granted"), type: .info)
        } else {
            toast.show(String(localized: "notif.settings.marketing_consent_withdrawn"), type: .info)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            Text("notif.settings.title")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)

            HStack {
                Button(action: onBack) {
                    Image("icChevronLeft")
                        .renderingMode(.template)
                        .foregroundStyle(Color.gray900)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    // MARK: - Toggle Row

    private func toggleRow(
        label: LocalizedStringKey,
        isOn: Bool,
        onChange: @escaping (Bool) -> Void,
        bottomPadding: CGFloat = .spacing16
    ) -> some View {
        HStack {
            Text(label)
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color.gray900)
            Spacer()
            boatSwitch(isOn: isOn, onChange: onChange)
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing16)
        .padding(.bottom, bottomPadding)
    }

    /// iOS/macOS 모두에서 동일하게 보이는 커스텀 스위치
    private func boatSwitch(isOn: Bool, onChange: @escaping (Bool) -> Void) -> some View {
        Button { onChange(!isOn) } label: {
            ZStack {
                Capsule()
                    .fill(isOn ? Color.brandPrimary : Color.gray300)
                    .frame(width: 51, height: 31)
                Circle()
                    .fill(Color.colorWhite)
                    .frame(width: 27, height: 27)
                    .offset(x: isOn ? 10 : -10)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isOn)
    }
}

#Preview {
    NotificationSettingsView(onBack: {})
        .environment(PermissionManager())
}
