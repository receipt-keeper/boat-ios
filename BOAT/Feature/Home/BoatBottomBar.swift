//
//  BoatBottomBar.swift
//  BOAT
//
//  플로팅 글래스모피즘 하단 탭 (목록/홈/마이). 디자인 스펙 정합:
//  - 높이 62 고정, Capsule(양끝 완전 라운드), 좌우 내부 패딩 20, 3탭 space-between
//  - Background Blur(.ultraThinMaterial) + Drop Shadow + 글래스 엣지
//  - 선택=brandPrimary + 연한 파란(brandQuaternary) 라운드 하이라이트 / 미선택=gray800
//  FAB(+)는 MainTabView에서 pill 우측에 별도 배치.
//

import SwiftUI

struct BoatBottomBar: View {

    @Binding var selection: MainTab
    var dimmed: Bool = false
    var onDimTap: () -> Void = {}

    private let barHeight: CGFloat = 62
    private let horizontalPadding: CGFloat = 20

    var body: some View {
        // 3탭 space-between: 목록=좌측 / 홈=중앙 / 마이=우측
        HStack(spacing: 0) {
            item(.list, icon: "icList", label: "tab.list")
            Spacer(minLength: 0)
            item(.home, icon: "icHome", label: "tab.home")
            Spacer(minLength: 0)
            item(.my, icon: "icProfile", label: "tab.my")
        }
        .animation(.easeOut(duration: 0.2), value: selection)
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().stroke(Color.colorWhite.opacity(0.6), lineWidth: 1))
        // 등록 메뉴 노출 시 pill도 함께 dim 처리 (탭하면 닫힘)
        .overlay {
            if dimmed {
                Capsule()
                    .fill(Color.black.opacity(0.35))
                    .onTapGesture { onDimTap() }
            }
        }
        .clipShape(Capsule())
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
            .foregroundStyle(selected ? Color.brandPrimary : Color.gray800)
            .frame(height: 46)          // 선택 하이라이트 높이 (62 pill 내 상하 8 여백)
            .padding(.horizontal, 16)   // 하이라이트 좌우 패딩
            // 선택 탭 뒤 연한 파란 라운드 하이라이트 (탭 전환 시 페이드)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.brandQuaternary)
                    .opacity(selected ? 1 : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
