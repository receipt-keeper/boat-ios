//
//  BoatBottomBar.swift
//  BOAT
//
//  플로팅 글래스모피즘 하단 탭 (목록/홈/마이). Android BoatFloatingBottomBar 1:1 대응:
//  - 높이 62 고정, Capsule(풀 스타디움), 안쪽 인셋 12(바깥 마진 20은 MainTabView에서 적용)
//  - 3탭 균등 1/3 분할 — 좁은 화면에서도 특정 탭이 캡슐 밖으로 밀리지 않도록 고정폭 대신 균등폭 사용
//  - 선택 하이라이트: 탭 폭 그대로(1/3) × 높이 50 스타디움, 배경 #CCE0FF @30%(ColorNavigationTabBg 대응)
//  - 아이콘: 선택=fill 에셋(brandSecondary 베이크) / 미선택=outline 에셋(gray900 베이크)
//  - 라벨: 선택 시 brandPrimary, 항상 Bold 10pt
//  - Background Blur(.ultraThinMaterial) + Drop Shadow(shadow_md3: Y3/blur15 + Y1/blur7)
//  FAB(+)는 MainTabView에서 pill 우측에 별도 배치.
//

import SwiftUI

struct BoatBottomBar: View {

    @Binding var selection: MainTab
    var dimmed: Bool = false
    var onDimTap: () -> Void = {}

    private let barHeight: CGFloat = 62
    private let innerInset: CGFloat = 12
    private let tabHighlightHeight: CGFloat = 50
    private let tabIconSize: CGFloat = 28

    var body: some View {
        // 3탭 균등 1/3 분할 (Android Modifier.weight(1f) 대응)
        HStack(spacing: 0) {
            item(.list, iconOutline: "icListOutline", iconFill: "icListFill", label: "tab.list")
            item(.home, iconOutline: "icHomeOutline", iconFill: "icHomeFill", label: "tab.home")
            item(.my, iconOutline: "icProfileOutline", iconFill: "icProfileFill", label: "tab.my")
        }
        .animation(.easeOut(duration: 0.2), value: selection)
        .padding(.horizontal, innerInset)
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        // Android(HazeStyle: backgroundColor=White, tint=White 12%)와 동일하게 흰색으로 틴트한
        // 프로스트 유리 — .ultraThinMaterial 단독으로는 배경(파란 히어로)의 색·명도를 그대로
        // 반영해 탁하고 어둡게 보인다.
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.colorWhite.opacity(0.12)))
        }
        // 등록 메뉴 노출 시 pill도 함께 dim 처리 (탭하면 닫힘)
        .overlay {
            if dimmed {
                Capsule()
                    .fill(Color.black.opacity(0.35))
                    .onTapGesture { onDimTap() }
            }
        }
        .clipShape(Capsule())
        // shadow_md3 2겹 레이어(Y3/blur15 + Y1/blur7). SwiftUI shadow()는 같은 alpha라도
        // Android Material elevation보다 훨씬 옅게 보여, 스펙(10%)보다 눈에 띄게 진하게 준다.
        .shadow(color: .black.opacity(0.32), radius: 15, x: 0, y: 3)
        .shadow(color: .black.opacity(0.28), radius: 7, x: 0, y: 1)
    }

    private func item(
        _ tab: MainTab,
        iconOutline: String,
        iconFill: String,
        label: LocalizedStringKey
    ) -> some View {
        let selected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                // 색상은 에셋에 이미 베이크되어 있어 별도 틴트 없이 그대로 렌더링한다
                // (선택=fill/brandSecondary, 미선택=outline/gray900 — Android Icon(tint=Unspecified/Gray900) 대응).
                Image(selected ? iconFill : iconOutline)
                    .resizable()
                    .scaledToFit()
                    .frame(width: tabIconSize, height: tabIconSize)
                Text(label)
                    .font(.pretendard(.bold, size: 10))
                    .foregroundStyle(selected ? Color.brandPrimary : Color.gray700)
            }
            .frame(maxWidth: .infinity)
            .frame(height: tabHighlightHeight)
            // 선택 탭 뒤 연한 파란 스타디움 하이라이트 — 탭 폭(1/3) 그대로, 탭 전환 시 페이드
            .background {
                Capsule()
                    .fill(Color(hex: "#CCE0FF").opacity(0.30))
                    .opacity(selected ? 1 : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
