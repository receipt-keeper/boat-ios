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

    @State private var pushEnabled = false
    @State private var marketingConsent = false
    @State private var toast = BoatToastState()

    var body: some View {
        VStack(spacing: 0) {
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
                onChange: setMarketingConsent
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        .boatToastHost(toast)
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
        let previous = pushEnabled
        pushEnabled = enabled
        Task {
            do {
                let result = try await NotificationSettingsRepository.shared.updateSettings(pushEnabled: enabled)
                pushEnabled = result.pushEnabled
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
            } catch {
                marketingConsent = previous
                toast.showError((error as? LocalizedError)?.errorDescription ?? "")
            }
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
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        HStack {
            Text(label)
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color.gray900)
            Spacer()
            Toggle("", isOn: Binding(get: { isOn }, set: onChange))
                .labelsHidden()
                .tint(Color.brandPrimary)
        }
        .padding(.horizontal, .spacing20)
        .padding(.vertical, .spacing16)
    }
}

#Preview {
    NotificationSettingsView(onBack: {})
}
