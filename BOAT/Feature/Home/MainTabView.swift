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
    // FAB 카메라/갤러리 → 영수증 등록 화면(자동 열기)
    @State private var showRegisterFromFab = false
    @State private var registerAutoOpen: ReceiptRegisterView.AutoOpen?
    // 목록 탭의 inner tab / 정렬 — 홈에서 이동 시 지정 가능
    @State private var listTab: ReceiptTab = .all
    @State private var listSort: ReceiptSort = .default

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
                            onCamera: { openRegisterFromFab(.camera) },
                            onGallery: { openRegisterFromFab(.gallery) }
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
            // FAB 카메라/갤러리 → 영수증 등록 화면(진입 즉시 해당 소스 열림)
            .fullScreenCover(isPresented: $showRegisterFromFab) {
                ReceiptRegisterView(
                    onBack: { showRegisterFromFab = false },
                    autoOpen: registerAutoOpen
                )
            }
    }

    private func openRegisterFromFab(_ action: ReceiptRegisterView.AutoOpen) {
        showAddMenu = false
        registerAutoOpen = action
        showRegisterFromFab = true
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .list:
            ReceiptListView(selectedTab: $listTab, selectedSort: $listSort)
        case .home:
            HomeView(onOpenList: { tab, sort in
                listTab = tab
                if let sort { listSort = sort }
                selection = .list
            })
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
    /// 목록 탭으로 이동 (탭, 정렬 지정). sort=nil이면 정렬 유지.
    var onOpenList: (ReceiptTab, ReceiptSort?) -> Void

    @State private var showReceiptRegister = false
    @State private var showNotifications = false
    @State private var showGeneral = false // 임시: 초기(false) ↔ 일반(true) 전환

    var body: some View {
        VStack(spacing: 0) {
            BoatHeader(
                onSearch: { /* TODO: 검색 */ },
                onNotification: { showNotifications = true }
            )

            // 임시(개발용) 상태 전환 토글 — 백엔드 데이터 유무 분기 대용
            Picker("", selection: $showGeneral) {
                Text("초기").tag(false)
                Text("일반").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, .spacing20)
            .padding(.bottom, .spacing8)

            if showGeneral {
                HomeGeneralView(
                    expiring: HomeMock.expiringWarranties,
                    recent: HomeMock.recentReceipts,
                    // 만료예정 > → 목록 만료예정 탭
                    onExpiringMore: { onOpenList(.expiring, nil) },
                    // 더보기 → 목록 전체 탭 + 최근 등록 순
                    onRecentMore: { onOpenList(.all, .recent) }
                )
            } else {
                initialContent
            }
        }
        .background(Color.gray50)
        .fullScreenCover(isPresented: $showReceiptRegister) {
            ReceiptRegisterView(onBack: { showReceiptRegister = false })
        }
        .fullScreenCover(isPresented: $showNotifications) {
            NotificationListView(onBack: { showNotifications = false })
        }
    }

    // 초기 홈 (데이터 없을 때) — 무료 분석 배너 + 등록 카드 + 광고 배너
    private var initialContent: some View {
        ScrollView {
            VStack(spacing: .spacing12) {
                FreeAnalysisBanner(
                    remaining: UserStore.shared.current?.freeAnalysisTokensRemaining ?? 3
                )

                Button {
                    showReceiptRegister = true
                } label: {
                    HomeCard(
                        title: "home.card.register.title",
                        desc: "home.card.register.desc",
                        minHeight: 260
                    )
                }
                .buttonStyle(.plain)

                HomeCard(
                    title: "home.card.popular.title",
                    desc: "home.card.popular.desc",
                    minHeight: 110
                )
            }
            .padding(.horizontal, .spacing20)
            .padding(.vertical, .spacing12)
        }
    }
}

// MARK: - 홈 카드 (영수증 등록 / 광고 배너)

private struct HomeCard: View {
    let title: LocalizedStringKey
    let desc: LocalizedStringKey
    var minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            Text(title)
                .font(.pretendard(.bold, size: 20))
                .foregroundStyle(Color.brandPrimary)
            Text(desc)
                .font(.pretendard(.regular, size: 13))
                .foregroundStyle(Color.gray500)
                .lineSpacing(2)
            Spacer(minLength: 0)
        }
        .padding(.spacing20)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
        .overlay(
            RoundedRectangle(cornerRadius: .rounded2xl)
                .stroke(Color.brandQuinary, lineWidth: 1)
        )
    }
}


