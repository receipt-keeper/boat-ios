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
    @State private var showNotifications = false
    @State private var showSearch = false
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
            // 어느 탭에서든 종 아이콘 → 알림 목록
            .fullScreenCover(isPresented: $showNotifications) {
                NotificationListView(onBack: { showNotifications = false })
            }
            // 어느 탭에서든 돋보기 → 검색
            .fullScreenCover(isPresented: $showSearch) {
                SearchView(onBack: { showSearch = false })
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
            ReceiptListView(
                selectedTab: $listTab,
                selectedSort: $listSort,
                onSearch: { showSearch = true },
                onNotification: { showNotifications = true }
            )
        case .home:
            HomeView(
                onOpenList: { tab, sort in
                    listTab = tab
                    if let sort { listSort = sort }
                    selection = .list
                },
                onSearch: { showSearch = true },
                onNotification: { showNotifications = true }
            )
        case .my:
            MyPageView(
                viewModel: viewModel,
                onSearch: { showSearch = true },
                onNotification: { showNotifications = true }
            )
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
    var onSearch: () -> Void = {}
    var onNotification: () -> Void

    @State private var showReceiptRegister = false
    @State private var showGeneral = false // 임시: 초기(false) ↔ 일반(true) 전환

    var body: some View {
        VStack(spacing: 0) {
            BoatHeader(
                showLogo: true,
                onSearch: onSearch,
                onNotification: onNotification
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
        .task { try? await CreditRepository.shared.fetchCredits() }
        .fullScreenCover(isPresented: $showReceiptRegister) {
            ReceiptRegisterView(onBack: { showReceiptRegister = false })
        }
    }

    // 초기 홈 (데이터 없을 때) — 무료 분석 배너 + 등록 카드 + 광고 배너
    private var initialContent: some View {
        ScrollView {
            VStack(spacing: .spacing12) {
                FreeAnalysisBanner(
                    remaining: CreditStore.shared.current?.remainingCount ?? 3
                )

                Button {
                    showReceiptRegister = true
                } label: {
                    ReceiptRegisterCard()
                }
                .buttonStyle(.plain)

                RepairServiceCard()
            }
            .padding(.horizontal, .spacing20)
            .padding(.vertical, .spacing12)
        }
    }
}

// MARK: - 영수증 등록하기 배너 (파란 배경 + 이미지)

private struct ReceiptRegisterCard: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing8) {
                    Text("home.card.register.title")
                        .font(.pretendard(.bold, size: 22))
                        .foregroundStyle(Color.colorWhite)
                        .lineSpacing(4)
                    Text("home.card.register.desc")
                        .font(.pretendard(.regular, size: 13))
                        .foregroundStyle(Color.colorWhite.opacity(0.85))
                        .lineSpacing(4)
                    Spacer(minLength: 0)
                }
                .padding(.top, .spacing20)
                .padding(.leading, .spacing20)
                Spacer(minLength: 0)
            }

            Image("img_receipt_upload")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
        }
        .frame(maxWidth: .infinity, minHeight: 196)
        .background(Color.brandPrimary, in: RoundedRectangle(cornerRadius: .rounded2xl))
        .clipped()
    }
}

// MARK: - 가전제품 AS 광고 배너 (흰 배경 + 이미지)

private struct RepairServiceCard: View {
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: .spacing8) {
                Text("home.card.popular.title")
                    .font(.pretendard(.bold, size: 16))
                    .foregroundStyle(Color.brandPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text("home.card.popular.desc")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundStyle(Color.gray500)
                    .lineSpacing(4)
            }
            Spacer(minLength: .spacing8)
            Image("img_banner_repair_service")
                .resizable()
                .scaledToFit()
                .frame(width: 80)
        }
        .padding(.horizontal, .spacing20)
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
        .overlay(
            RoundedRectangle(cornerRadius: .rounded2xl)
                .strokeBorder(Color.brandTertiary, lineWidth: 1)
        )
    }
}


