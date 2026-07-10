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
    /// 알림 아이콘 우상단에 미읽음 표시(빨간 점) 노출 여부
    var showUnreadBadge: Bool = false
    /// 타이틀/아이콘 색상 — 홈처럼 그라데이션 배경 위에서는 .colorWhite로 오버라이드.
    var tint: Color = .gray900
    var onSearch: () -> Void = {}
    var onNotification: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            if showLogo {
                Text("header.home_title")
                    .font(.pretendard(.bold, size: 22))
                    .foregroundStyle(tint)
            } else {
                Text(title)
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(tint)
            }

            Spacer(minLength: 0)

            actionIcon("icSearch", label: "header.search", action: onSearch)
            Spacer().frame(width: .spacing16)
            actionIcon("icBell", label: "header.notification", showBadge: showUnreadBadge, action: onNotification)
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    private func actionIcon(
        _ name: String,
        label: LocalizedStringKey,
        showBadge: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(tint)
                .contentShape(Rectangle())
                .overlay(alignment: .topTrailing) {
                    if showBadge {
                        Circle()
                            .fill(Color.systemError)
                            .frame(width: 8, height: 8)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}
