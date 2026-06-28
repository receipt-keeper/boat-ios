//
//  BoatHeader.swift
//  BOAT
//
//  공통 헤더 — 좌측 로고(또는 타이틀), 우측 검색/알림 아이콘.
//  Android BoatHeader 대응. 여러 화면에서 재사용한다.
//

import SwiftUI

struct BoatHeader: View {

    var title: LocalizedStringKey = "header.logo"
    var showLogo: Bool = false
    var onSearch: () -> Void = {}
    var onNotification: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            if showLogo {
                Image("app_logo_text")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            } else {
                Text(title)
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(Color.gray900)
            }

            Spacer(minLength: 0)

            actionIcon("icSearch", label: "header.search", action: onSearch)
            Spacer().frame(width: .spacing16)
            actionIcon("icBell", label: "header.notification", action: onNotification)
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    private func actionIcon(
        _ name: String,
        label: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.gray900)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}
