//
//  BoatBottomBar.swift
//  BOAT
//
//  커스텀 하단 Bottom Navigation. Android BoatBottomBar 디자인 동일.
//  흰 배경 + 상단 헤어라인, 아이콘 위 라벨, 선택=brandPrimary / 비선택=gray400.
//

import SwiftUI

struct BoatBottomBar: View {

    @Binding var selection: MainTab

    var body: some View {
        HStack(spacing: 0) {
            item(.list, icon: "icList", label: "tab.list")
            item(.home, icon: "icHome", label: "tab.home")
            item(.my, icon: "icProfile", label: "tab.my")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .spacing8)
        .padding(.bottom, .spacing4)
        .background(
            Color.colorWhite
                .ignoresSafeArea(edges: .bottom) // 홈 인디케이터 영역까지 흰색
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray200)
                .frame(height: 0.5)
        }
    }

    private func item(
        _ tab: MainTab,
        icon: String,
        label: LocalizedStringKey
    ) -> some View {
        let selected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: .spacing4) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                Text(label)
                    .font(.pretendard(.medium, size: 11))
            }
            .foregroundStyle(selected ? Color.brandPrimary : Color.gray400)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
