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

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.colorWhite)
            // 스크림 (메뉴 열릴 때, 탭하면 닫힘) — 플로팅 바보다 아래 레이어
            .overlay {
                if showAddMenu {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { showAddMenu = false }
                }
            }
            // 플로팅 글래스 하단 바 (탭 pill + FAB) — 스크림 위로 떠오름
            .overlay(alignment: .bottom) {
                HStack(spacing: .spacing12) {
                    BoatBottomBar(
                        selection: $selection,
                        dimmed: showAddMenu,
                        onDimTap: { showAddMenu = false }
                    )
                    fabButton
                }
                .padding(.horizontal, .spacing20)
                .padding(.bottom, .spacing8)
            }
            // 등록 메뉴 카드 — FAB 위쪽, 오른쪽 변을 FAB 중앙에 정렬
            .overlay(alignment: .bottomTrailing) {
                if showAddMenu {
                    ReceiptAddMenuCard(
                        onCamera: { openRegisterFromFab(.camera) },
                        onGallery: { openRegisterFromFab(.gallery) }
                    )
                    .padding(.trailing, 51) // FAB 중앙 (외곽 20 + 반지름 31)
                    .padding(.bottom, 82)   // FAB(하단 8 + 62) + 간격 12 위로
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showAddMenu)
            // 로그인 상태로 메인 진입 시 FCM 디바이스 등록 (멱등 — 신규 로그인/앱 재실행 공통 커버)
            .task { await FCMDeviceManager.shared.register() }
            // 알림 차단 상태면 앱 진입/복귀마다 권한 요청 또는 설정 유도
            .background(NotificationPermissionGate())
            // FAB 카메라/갤러리 → 영수증 등록 화면(진입 즉시 해당 소스 열림)
            .fullScreenCover(isPresented: $showRegisterFromFab) {
                ReceiptRegisterView(
                    onBack: { showRegisterFromFab = false },
                    autoOpen: registerAutoOpen,
                    onComplete: { showRegisterFromFab = false }
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
            // 푸시 알림 탭 → 영수증 상세 (NotificationRouter가 payload의 resourceId를 세팅)
            .fullScreenCover(item: pushReceiptBinding) { rid in
                ReceiptDetailView(receiptId: rid.id, onBack: { NotificationRouter.shared.pendingReceiptId = nil })
            }
    }

    private var pushReceiptBinding: Binding<IdentifiedID?> {
        Binding(
            get: { NotificationRouter.shared.pendingReceiptId.map(IdentifiedID.init) },
            set: { newValue in
                if newValue == nil { NotificationRouter.shared.pendingReceiptId = nil }
            }
        )
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
                .foregroundStyle(Color.gray900)
                .frame(width: 62, height: 62) // pill 높이와 동일
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle().stroke(Color.colorWhite.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
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
    @State private var isInitializing = true
    // 홈 콘텐츠 — 등록된 영수증이 있으면 일반(요약 대시보드), 없으면 초기(온보딩) 화면
    @State private var hasAnyReceipts = false
    @State private var expiringWarranties: [ExpiringWarranty] = []
    @State private var expiringTotalCount = 0
    @State private var recentReceipts: [RecentReceipt] = []

    var body: some View {
        ZStack {
            // 헤더까지 포함해 전체 화면이 하나로 스크롤된다 (Top Bar는 고정되지 않음).
            ScrollView {
                VStack(spacing: 0) {
                    BoatHeader(
                        showLogo: true,
                        tint: .colorWhite,
                        onSearch: onSearch,
                        onNotification: onNotification
                    )

                    if hasAnyReceipts {
                        HomeGeneralView(
                            expiring: expiringWarranties,
                            expiringTotalCount: expiringTotalCount,
                            recent: recentReceipts,
                            // 만료예정 > → 목록 만료예정 탭 + 만료 임박순 정렬 자동 선택
                            onExpiringMore: { onOpenList(.expiring, .expiring) },
                            // 더보기 → 목록 전체 탭 + 최근 등록 순
                            onRecentMore: { onOpenList(.all, .recent) }
                        )
                    } else {
                        initialContent
                    }
                }
            }

            // 초기 로딩 중에는 HomeLoadingView가 전체를 덮음
            if isInitializing {
                HomeLoadingView()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 상단 그라데이션 히어로 배경(고정). 홈 화면이면 상태(초기/일반) 무관하게 동일 적용.
        .background(alignment: .top) {
            LinearGradient(
                colors: [Color.brandSecondary, Color.brandPrimary, Color.brandPrimary.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 560)
            .ignoresSafeArea(edges: .top)
        }
        .background(Color.gray50)
        .task {
            // 첫 홈 진입/재방문 시마다 초기 API 병렬 호출 — 모두 완료되면 로딩 해제
            async let credits: Void = { try? await CreditRepository.shared.fetchCredits() }()
            async let user: Void = { try? await UserRepository.shared.refreshUser() }()
            // AS 만료 예정: 만료 임박순(가까운 순서) / 최근 등록: 등록일 내림차순
            async let expiring = try? await ReceiptRepository.shared.fetchReceipts(tab: .expiring, sort: .expiring, filter: .all)
            async let recent = try? await ReceiptRepository.shared.fetchReceipts(tab: .all, sort: .recent, filter: .all)

            let (_, _, expiringData, recentData) = await (credits, user, expiring, recent)

            expiringWarranties = expiringData?.receipts.prefix(5).map { $0.toExpiringWarranty() } ?? []
            expiringTotalCount = expiringData?.pagination.totalCount ?? expiringWarranties.count
            recentReceipts = recentData?.receipts.prefix(5).map { $0.toRecentReceipt() } ?? []
            hasAnyReceipts = (recentData?.pagination.totalCount ?? 0) > 0

            withAnimation(.easeOut(duration: 0.3)) {
                isInitializing = false
            }
        }
        .fullScreenCover(isPresented: $showReceiptRegister) {
            ReceiptRegisterView(
                onBack: { showReceiptRegister = false },
                onComplete: { showReceiptRegister = false }
            )
        }
    }

    // 초기 홈 (데이터 없을 때) — 등록 유도 배너(그라데이션 히어로 위) + 광고 배너
    private var initialContent: some View {
        VStack(spacing: .spacing16) {
            Button {
                showReceiptRegister = true
            } label: {
                ReceiptRegisterCard()
            }
            .buttonStyle(.plain)

            AccessoryBanner()
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing16)
        .padding(.bottom, 92) // 플로팅 하단 바 높이만큼 여백
    }
}

// MARK: - 영수증 등록하기 배너 (신규 img_cta_banner 에셋 그대로 사용)

private struct ReceiptRegisterCard: View {
    var body: some View {
        Image("img_cta_banner")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: .rounded3xl))
            .overlay(
                RoundedRectangle(cornerRadius: .rounded3xl)
                    .stroke(Color.colorWhite.opacity(0.6), lineWidth: 1)
            )
    }
}


