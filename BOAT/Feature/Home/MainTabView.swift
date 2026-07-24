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
    @Environment(\.scenePhase) private var scenePhase
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
    // 서비스 피드백 시트 제출 결과 토스트
    @State private var toast = BoatToastState()
    // 피드백 시트 실측 높이 — 별점 선택 전/후 콘텐츠 높이가 달라 고정값을 쓰지 않는다.
    // 매번 노출될 때 접힌 상태 높이로 리셋해, 이전 세션에서 펼쳐졌던 높이가 다음 노출 때
    // 잠깐 크게 보였다가 줄어드는 깜빡임을 방지한다.
    @State private var feedbackSheetHeight: CGFloat = Self.feedbackCollapsedHeight
    private static let feedbackCollapsedHeight: CGFloat = 330

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
                .padding(.bottom, .spacing12)
            }
            // 등록 메뉴 카드 — FAB 위쪽, 오른쪽 변을 FAB 우측 변에 정렬
            .overlay(alignment: .bottomTrailing) {
                if showAddMenu {
                    ReceiptAddMenuCard(
                        onCamera: { openRegisterFromFab(.camera) },
                        onGallery: { openRegisterFromFab(.gallery) }
                    )
                    .padding(.trailing, .spacing20) // FAB 우측 변과 동일(화면 외곽 20)
                    .padding(.bottom, 86)   // FAB(하단 12 + 62) + 간격 12 위로
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showAddMenu)
            // 로그인 상태로 메인 진입 시 FCM 디바이스 등록 (멱등 — 신규 로그인/앱 재실행 공통 커버)
            .task { await FCMDeviceManager.shared.register() }
            // 헤더 종 아이콘 Red Dot 상태 — 진입 시 + 포그라운드 복귀(백그라운드 중 푸시 수신) 시 갱신
            .task { await NotificationBadgeStore.shared.refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await NotificationBadgeStore.shared.refresh() }
                }
            }
            // 가입/로그인 후 앱을 완전히 껐다가 재실행했을 때만(콜드 스타트 1회) 권한 요청 또는 설정 유도
            .background(NotificationPermissionGate())
            // FAB 카메라/갤러리 → 영수증 등록 화면(진입 즉시 해당 소스 열림)
            .fullScreenCover(isPresented: $showRegisterFromFab) {
                ReceiptRegisterView(
                    onBack: { showRegisterFromFab = false },
                    autoOpen: registerAutoOpen,
                    // 어느 탭에서 FAB로 진입했든 "홈으로 가기"는 반드시 홈 탭으로 이동해야 한다.
                    onComplete: { showRegisterFromFab = false; selection = .home }
                )
            }
            // 어느 탭에서든 종 아이콘 → 알림 목록
            // onBack은 상단바 뒤로가기뿐 아니라 상시 유도 알림 탭(홈으로 라우팅)에서도 호출되므로,
            // 알림 목록 화면을 어떤 경로로 나가든 피드백 시트 노출을 시도한다(Android NotificationListActivity 동일).
            .fullScreenCover(isPresented: $showNotifications) {
                NotificationListView(onBack: {
                    FeedbackTrigger.shared.trigger()
                    showNotifications = false
                })
            }
            // 어느 탭에서든 돋보기 → 검색
            .fullScreenCover(isPresented: $showSearch) {
                SearchView(
                    onBack: { showSearch = false },
                    // 검색 결과에서 연 상세를 삭제하면 검색 화면을 닫고 목록 탭(갱신됨)으로 이동.
                    onDeleted: {
                        showSearch = false
                        selection = .list
                    }
                )
            }
            // 푸시 알림 탭 → 영수증 상세 (NotificationRouter가 payload의 resourceId를 세팅)
            .fullScreenCover(item: pushReceiptBinding) { rid in
                ReceiptDetailView(receiptId: rid.id, onBack: { NotificationRouter.shared.pendingReceiptId = nil })
            }
            // 마케팅 알림(푸시 탭 또는 인앱 알림 목록 탭) → 홈 탭으로 전환.
            // 탭만 바꿔서는 이미 떠 있는 fullScreenCover(검색/알림 목록/이전 상세 등)가 안 닫히므로
            // 여기서 소유한 모달들을 함께 정리한다. (같은 탭이면 switch로도 안 바뀌므로 필수)
            .onChange(of: NotificationRouter.shared.shouldOpenHome) { _, shouldOpen in
                guard shouldOpen else { return }
                selection = .home
                showSearch = false
                showNotifications = false
                showRegisterFromFab = false
                NotificationRouter.shared.pendingReceiptId = nil
                NotificationRouter.shared.shouldOpenHome = false
            }
            // 상시 유도 알림(푸시 탭 또는 인앱 알림 목록 탭) → 영수증 업로드 화면으로 이동.
            // FAB 등록과 동일한 fullScreenCover(showRegisterFromFab)를 재사용한다.
            .onChange(of: NotificationRouter.shared.shouldOpenReceiptRegister) { _, shouldOpen in
                guard shouldOpen else { return }
                showSearch = false
                showNotifications = false
                showRegisterFromFab = true
                NotificationRouter.shared.pendingReceiptId = nil
                NotificationRouter.shared.shouldOpenReceiptRegister = false
            }
            // 영수증 등록 성공 등 특정 액션 이후 서비스 만족도 피드백 시트 노출 시도.
            .onChange(of: FeedbackTrigger.shared.triggerCount) { _, _ in
                UserFeedbackStore.shared.tryShowFeedback()
            }
            // 매번 새로 뜰 때는 항상 접힌 상태 높이로 시작 — 이전 노출 때 별점을 찍어 늘어났던
            // 높이가 다음 노출 시 그대로 남아있지 않도록 리셋한다.
            .onChange(of: UserFeedbackStore.shared.showFeedbackSheet) { _, isShowing in
                if isShowing { feedbackSheetHeight = Self.feedbackCollapsedHeight }
            }
            .sheet(isPresented: feedbackSheetBinding) {
                BoatFeedbackSheet(
                    onDismiss: { UserFeedbackStore.shared.onFeedbackDismissed() },
                    onNext: { UserFeedbackStore.shared.onFeedbackPostponed() },
                    onSubmit: { rating, comment in
                        if UserFeedbackStore.shared.submitFeedback(rating: rating, comment: comment) {
                            toast.showSuccess(String(localized: "feedback.submit_success"))
                        } else {
                            toast.showError(String(localized: "feedback.submit_error"))
                        }
                    },
                    onHeightChange: { feedbackSheetHeight = $0 }
                )
                .presentationDetents([.height(feedbackSheetHeight)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.colorWhite)
            }
            .boatToastHost(toast)
    }

    private var pushReceiptBinding: Binding<IdentifiedID?> {
        Binding(
            get: { NotificationRouter.shared.pendingReceiptId.map(IdentifiedID.init) },
            set: { newValue in
                if newValue == nil { NotificationRouter.shared.pendingReceiptId = nil }
            }
        )
    }

    private var feedbackSheetBinding: Binding<Bool> {
        Binding(
            get: { UserFeedbackStore.shared.showFeedbackSheet },
            set: { newValue in
                if !newValue { UserFeedbackStore.shared.showFeedbackSheet = false }
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
                onNotification: { showNotifications = true },
                onGoHome: { selection = .home }
            )
        }
    }

    private var fabButton: some View {
        Button {
            showAddMenu.toggle()
        } label: {
            Image("icPlus")
                .renderingMode(.template)
                .foregroundStyle(Color.gray900)
                // 메뉴가 열리면 +가 45도 회전해 X 모양이 되고, 탭하면 닫힘(toggle)
                .rotationEffect(.degrees(showAddMenu ? 45 : 0))
                .frame(width: 62, height: 62) // pill 높이와 동일
                // 하단 탭 pill과 동일한 흰색 틴트 프로스트 유리(Android HazeStyle 대응)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(Circle().fill(Color.colorWhite.opacity(0.12)))
                }
                .overlay(
                    Circle().stroke(Color.colorWhite, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 16, y: 6)
        }
        .accessibilityLabel(Text(showAddMenu ? "detail.menu_close" : "receipt.add"))
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
    // 직전(마지막 조회)에 영수증이 있었는지 — 콜드 스타트 시 어떤 스켈레톤(일반/초기)을 보여줄지 결정.
    @AppStorage("boat.home.hadReceipts") private var hadReceiptsLastTime = false
    @State private var expiringWarranties: [ExpiringWarranty] = []
    @State private var expiringTotalCount = 0
    @State private var recentReceipts: [RecentReceipt] = []
    @State private var toast = BoatToastState()
    // 카드(만료 예정/최근 등록) 탭 → 영수증 상세
    @State private var detailReceiptId: IdentifiedID?

    var body: some View {
        ZStack {
            // 헤더까지 포함해 전체 화면이 하나로 스크롤된다 (Top Bar는 고정되지 않음).
            ScrollView {
                VStack(spacing: 0) {
                    // 디자인 가이드 확인 결과 상태바 바로 아래 12pt 간격 필요 (기존엔 safe area 뒤 곧바로 헤더가 붙어 너무 가까움).
                    Spacer().frame(height: 12)

                    BoatHeader(
                        showLogo: true,
                        showUnreadBadge: NotificationBadgeStore.shared.hasUnread,
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
                            onRecentMore: { onOpenList(.all, .recent) },
                            onExpiringTap: { detailReceiptId = IdentifiedID(id: $0.id) },
                            onRecentTap: { detailReceiptId = IdentifiedID(id: $0.id) }
                        )
                    } else {
                        initialContent
                    }
                }
            }

            // 초기 로딩(API 조회) 중에는 스켈레톤이 전체를 덮음.
            // 직전에 영수증이 있었으면 일반(대시보드) 스켈레톤, 없었으면 초기 스켈레톤.
            if isInitializing {
                HomeSkeleton(hasList: hadReceiptsLastTime)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 상단 그라데이션 히어로 배경(고정, 화면 전체 배경). 홈 화면이면 상태(초기/일반) 무관하게 동일 적용.
        // Android 기준: 블루(#3E82F7) → 흰색 2-stop 그라데이션. 아래쪽은 순수 흰 배경이라야
        // 최근 등록 카드(#F2F6FC)의 옅은 쿨블루가 배경과 구분돼 보인다(gray50과는 거의 구분 안 됨).
        .background(alignment: .top) {
            LinearGradient(
                colors: [Color(hex: "#3E82F7"), Color.colorWhite],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 560)
            .ignoresSafeArea(edges: .top)
        }
        .background(Color.colorWhite)
        .boatToastHost(toast)
        .task {
            // 첫 홈 진입 시에만 전체 로딩 오버레이를 덮는다.
            await loadHomeData()
            withAnimation(.easeOut(duration: 0.3)) {
                isInitializing = false
            }
        }
        // 다른 화면(등록/수정/삭제)에서 일어난 변경도 반영 — 조용히 재조회(로딩 오버레이 없이).
        .onChange(of: ReceiptChangeBus.shared.version) { _, _ in
            Task { await loadHomeData() }
        }
        // 마케팅 알림 탭 시 홈으로 이동 — 이미 홈 탭이면 MainTabView의 selection이 안 바뀌어
        // 이 화면 자체는 새로 그려지지 않으므로, 여기서 직접 열려있던 상세/등록 화면을 닫아준다.
        .onChange(of: NotificationRouter.shared.shouldOpenHome) { _, shouldOpen in
            guard shouldOpen else { return }
            detailReceiptId = nil
            showReceiptRegister = false
        }
        .fullScreenCover(isPresented: $showReceiptRegister) {
            ReceiptRegisterView(
                onBack: { showReceiptRegister = false },
                onComplete: { showReceiptRegister = false }
            )
        }
        // 만료 예정/최근 등록 카드 탭 → 영수증 상세
        .fullScreenCover(item: $detailReceiptId) { rid in
            ReceiptDetailView(
                receiptId: rid.id,
                onBack: { detailReceiptId = nil },
                onDeleted: {
                    detailReceiptId = nil
                    toast.show(String(localized: "detail.deleted_toast"), type: .info)
                }
            )
        }
    }

    /// AS 만료 예정 / 최근 등록 데이터 병렬 조회. 진입 시(.task)와 ReceiptChangeBus 변경 시 모두 재사용.
    private func loadHomeData() async {
        async let credits: Void = {
            _ = try? await CreditRepository.shared.fetchCredits()
        }()
        async let user: Void = {
            _ = try? await UserRepository.shared.refreshUser()
        }()
        // AS 만료 예정: 만료 임박순(가까운 순서) / 최근 등록: 등록일 내림차순
        async let expiring = try? await ReceiptRepository.shared.fetchReceipts(tab: .expiring, sort: .expiring, filter: .all)
        async let recent = try? await ReceiptRepository.shared.fetchReceipts(tab: .all, sort: .recent, filter: .all)

        let (_, _, expiringData, recentData) = await (credits, user, expiring, recent)

        expiringWarranties = expiringData?.receipts.prefix(5).map { $0.toExpiringWarranty() } ?? []
        // "N건"은 표시되는 카드 수가 아니라 만료 예정 목록 API의 전체 totalCount를 그대로 따른다.
        expiringTotalCount = expiringData?.totalCount ?? expiringWarranties.count
        recentReceipts = recentData?.receipts.prefix(5).map { $0.toRecentReceipt() } ?? []
        hasAnyReceipts = (recentData?.totalCount ?? 0) > 0
        // 다음 콜드 스타트 때 올바른 스켈레톤을 고르도록 최신 상태 저장. (recent 조회 성공 시에만)
        if recentData != nil { hadReceiptsLastTime = hasAnyReceipts }
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

            BoatNativeAdBanner()
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing16)
        .padding(.bottom, 96) // 플로팅 하단 바 높이만큼 여백
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
