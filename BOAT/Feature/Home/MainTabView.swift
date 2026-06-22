//
//  MainTabView.swift
//  BOAT
//
//  로그인 이후 메인 화면 호스트. Android MainScreen + BoatBottomBar 대응.
//  하단 탭: 목록 / 홈 / 마이 (기본 선택: 홈).
//  ※ 각 탭의 실제 화면 디자인은 보류 — 현재는 플레이스홀더.
//

import SwiftUI

enum MainTab: Hashable {
    case list, home, my
}

struct MainTabView: View {

    let viewModel: AuthViewModel
    @State private var selection: MainTab = .home
    @State private var showAddMenu = false

    // FAB는 홈/목록 탭에서만 노출 (마이 탭 제외)
    private var showFab: Bool {
        selection == .home || selection == .list
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.colorWhite)
            // 스크림 + FAB + 메뉴 카드를 같은 좌표계(바 위)에 배치
            .overlay(alignment: .bottomTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    // 스크림 (메뉴 열릴 때, 탭하면 닫힘)
                    if showAddMenu {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture { showAddMenu = false }
                    }
                    // FAB — 메뉴 열려도 계속 보이게 (스크림 위)
                    if showFab {
                        fabButton
                            .padding(.trailing, .spacing16)
                            .padding(.bottom, .spacing16)
                    }
                    // 메뉴 카드 — FAB 위쪽, 오른쪽 변을 FAB 중앙(우측 44pt)에 정렬
                    if showAddMenu {
                        ReceiptAddMenuCard(
                            onCamera: { showAddMenu = false /* TODO: 카메라 촬영 → 영수증 등록 */ },
                            onGallery: { showAddMenu = false /* TODO: 갤러리 선택 → 영수증 등록 */ }
                        )
                        .padding(.trailing, 44) // FAB 중앙 (end 16 + 반지름 28)
                        .padding(.bottom, 84) // FAB(56) + 하단 16 + 간격 12 위로
                    }
                }
            }
            // 커스텀 하단 바 (콘텐츠 + 오버레이를 자동으로 바 위로 인셋)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BoatBottomBar(
                    selection: $selection,
                    dimmed: showAddMenu,
                    onDimTap: { showAddMenu = false }
                )
            }
            .animation(.easeInOut(duration: 0.2), value: showAddMenu)
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .list:
            TabPlaceholderView(titleKey: "tab.list")
        case .home:
            HomeView()
        case .my:
            MyPageView(viewModel: viewModel)
        }
    }

    private var fabButton: some View {
        Button {
            showAddMenu = true
        } label: {
            Image("icPlus")
                .renderingMode(.template)
                .foregroundStyle(Color.colorWhite)
                .frame(width: 56, height: 56)
                .background(Color.gray900, in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .accessibilityLabel(Text("receipt.add"))
    }
}

// MARK: - 홈 (공통 헤더 + 본문 placeholder, 디자인 보류)

private struct HomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            BoatHeader(
                onSearch: { /* TODO: 검색 */ },
                onNotification: { /* TODO: 알림 */ }
            )
            Text("tab.home")
                .font(.pretendard(.semibold, size: 18))
                .foregroundStyle(Color.gray400)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.colorWhite)
    }
}

// MARK: - 임시 플레이스홀더 (목록 디자인 보류)

private struct TabPlaceholderView: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        Text(titleKey)
            .font(.pretendard(.semibold, size: 18))
            .foregroundStyle(Color.gray400)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.colorWhite)
    }
}

