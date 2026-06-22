//
//  NotificationSettingsView.swift
//  BOAT
//
//  알림 설정 화면. Android NotificationSettingsScreen 대응.
//  네이티브 Toggle(primary 색상)로 알림/마케팅 수신 동의를 토글.
//  TODO: 토글 상태 영속화 + 실제 알림 권한/마케팅 수신 동의 연동
//

import SwiftUI

struct NotificationSettingsView: View {

    let onBack: () -> Void

    @State private var alarmEnabled = true
    @State private var marketingEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Spacer().frame(height: .spacing8)

            toggleRow(label: "notif.settings.alarm", isOn: $alarmEnabled)
            toggleRow(label: "notif.settings.marketing", isOn: $marketingEnabled)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
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

    private func toggleRow(label: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color.gray900)
            Spacer()
            Toggle("", isOn: isOn)
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
