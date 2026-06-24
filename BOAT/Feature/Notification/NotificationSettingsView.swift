//
//  NotificationSettingsView.swift
//  BOAT
//
//  알림 설정 화면. Android NotificationSettingsScreen/ViewModel 대응.
//  토글 변경 → PATCH /users/me 로 서버 반영 + 로컬 캐시(UserStore) 동기화.
//  실패 시 에러 토스트 + 서버 기준 복구.
//

import SwiftUI

struct NotificationSettingsView: View {

    let onBack: () -> Void

    private let store = UserStore.shared
    @State private var toast = BoatToastState()

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Spacer().frame(height: .spacing8)

            toggleRow(
                label: "notif.settings.alarm",
                isOn: store.current?.notificationEnabled ?? false,
                onChange: setNotificationEnabled
            )
            toggleRow(
                label: "notif.settings.marketing",
                isOn: store.current?.marketingConsent ?? false,
                onChange: setMarketingConsent
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        .boatToastHost(toast)
        .task {
            // 최신 서버 값 동기화
            try? await UserRepository.shared.refreshUser()
        }
    }

    // MARK: - 토글 동작 (PATCH + 실패 복구)

    private func setNotificationEnabled(_ enabled: Bool) {
        guard store.current?.notificationEnabled != enabled else { return } // 변경 없음 → 불필요한 PATCH 방지
        Task {
            do {
                try await UserRepository.shared.updateMe(notificationEnabled: enabled)
            } catch {
                toast.showError((error as? LocalizedError)?.errorDescription ?? "")
                try? await UserRepository.shared.refreshUser() // 서버 기준 복구
            }
        }
    }

    private func setMarketingConsent(_ consent: Bool) {
        guard store.current?.marketingConsent != consent else { return }
        Task {
            do {
                try await UserRepository.shared.updateMe(marketingConsent: consent)
            } catch {
                toast.showError((error as? LocalizedError)?.errorDescription ?? "")
                try? await UserRepository.shared.refreshUser()
            }
        }
    }

    // MARK: - Top Bar (뒤로가기 + 알림설정)

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
