//
//  BoatBottomBar.swift
//  BOAT
//
//  플로팅 글래스모피즘 하단 탭 (목록/홈/마이).
//  화면 하단에 떠 있는 pill 형태 — .ultraThinMaterial 블러 + 글래스 엣지 + 그림자.
//  선택=brandPrimary / 비선택=gray400. FAB(+)는 MainTabView에서 pill 우측에 별도 배치.
//

import SwiftUI

struct BoatBottomBar: View {

    @Binding var selection: MainTab
    var dimmed: Bool = false
    var onDimTap: () -> Void = {}

    private let cornerRadius: CGFloat = 28

    var body: some View {
        HStack(spacing: 0) {
            item(.list, icon: "icList", label: "tab.list")
            item(.home, icon: "icHome", label: "tab.home")
            item(.my, icon: "icProfile", label: "tab.my")
        }
        .animation(.easeOut(duration: 0.2), value: selection)
        .padding(.vertical, .spacing8)
        .padding(.horizontal, .spacing8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.colorWhite.opacity(0.6), lineWidth: 1)
        )
        // 등록 메뉴 노출 시 pill도 함께 dim 처리 (탭하면 닫힘)
        .overlay {
            if dimmed {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .onTapGesture { onDimTap() }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
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
                    .frame(width: 24, height: 24)
                Text(label)
                    .font(.pretendard(.medium, size: 11))
            }
            .foregroundStyle(selected ? Color.brandPrimary : Color.gray400)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            // 선택 탭 뒤 연한 파란 라운드 하이라이트 (탭 전환 시 페이드)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.brandQuaternary)
                    .opacity(selected ? 1 : 0)
                    .padding(.horizontal, .spacing8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
