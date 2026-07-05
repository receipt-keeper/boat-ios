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
                    if showFab {
                        fabButton
                    }
                }
                .padding(.horizontal, .spacing16)
                .padding(.bottom, .spacing8)
            }
            // 등록 메뉴 카드 — FAB 위쪽, 오른쪽 변을 FAB 중앙(우측 44pt)에 정렬
            .overlay(alignment: .bottomTrailing) {
                if showAddMenu {
                    ReceiptAddMenuCard(
                        onCamera: { openRegisterFromFab(.camera) },
                        onGallery: { openRegisterFromFab(.gallery) }
                    )
                    .padding(.trailing, 44) // FAB 중앙 (end 16 + 반지름 28)
                    .padding(.bottom, 76)   // FAB(하단 8 + 56) + 간격 12 위로
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showAddMenu)
            // 로그인 상태로 메인 진입 시 FCM 디바이스 등록 (멱등 — 신규 로그인/앱 재실행 공통 커버)
            .task { await FCMDeviceManager.shared.register() }
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
                .frame(width: 56, height: 56)
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
    @State private var showGeneral = false // 임시: 초기(false) ↔ 일반(true) 전환
    @State private var isInitializing = true
    // [TEST] 푸시 발송 다이얼로그 (DEBUG 전용)
    @State private var showTestPushAlert = false
    @State private var testPushTitle = "테스트 알림"
    @State private var testPushBody = "푸시 연결 확인용 테스트 메시지입니다."
    @State private var toast = BoatToastState()

    var body: some View {
        VStack(spacing: 0) {
            BoatHeader(
                showLogo: true,
                onSearch: onSearch,
                onNotification: onNotification
            )

            // 헤더 아래 컨텐츠 영역 — 초기 로딩 중에는 HomeLoadingView가 덮음
            ZStack {
                VStack(spacing: 0) {
                    #if DEBUG
                    // [TEST] FCM 연동 확인용 — 등록된 모든 디바이스로 테스트 푸시 즉시 발송
                    Button {
                        showTestPushAlert = true
                    } label: {
                        Text("[TEST] 푸시")
                            .font(.pretendard(.medium, size: 12))
                            .foregroundStyle(Color.brandPrimary)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, .spacing20)
                    .padding(.bottom, 2)
                    #endif

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
                            // 만료예정 > → 목록 만료예정 탭 + 만료 임박순 정렬 자동 선택
                            onExpiringMore: { onOpenList(.expiring, .expiring) },
                            // 더보기 → 목록 전체 탭 + 최근 등록 순
                            onRecentMore: { onOpenList(.all, .recent) }
                        )
                    } else {
                        initialContent
                    }
                }

                if isInitializing {
                    HomeLoadingView()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.gray50)
        .task {
            // 첫 홈 진입 시 초기 API 병렬 호출 — 모두 완료되면 로딩 해제
            await withTaskGroup(of: Void.self) { group in
                group.addTask { try? await CreditRepository.shared.fetchCredits() }
                group.addTask { try? await UserRepository.shared.refreshUser() }
                for await _ in group {}
            }
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
        #if DEBUG
        .alert("테스트 푸시 발송", isPresented: $showTestPushAlert) {
            TextField("제목", text: $testPushTitle)
            TextField("내용", text: $testPushBody)
            Button("common.cancel", role: .cancel) {}
            Button("발송") { sendTestPush() }
        } message: {
            Text("등록된 모든 디바이스로 즉시 발송됩니다.")
        }
        #endif
        .boatToastHost(toast)
    }

    #if DEBUG
    /// [TEST] POST /api/v1/example/push — 로그인 사용자의 등록된 모든 디바이스로 테스트 푸시 발송.
    private func sendTestPush() {
        let title = testPushTitle.trimmingCharacters(in: .whitespaces)
        let body = testPushBody.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, !body.isEmpty else { return }
        Task {
            do {
                let result: TestPushData = try await APIClient.shared.request(
                    ExampleTarget.testPush(title: title, body: body)
                )
                toast.showSuccess("발송 완료 (대상 \(result.targetedDeviceCount)대, 무효 \(result.invalidDeviceCount)대)")
            } catch {
                toast.showError((error as? LocalizedError)?.errorDescription ?? String(localized: "error.api.unknown"))
            }
        }
    }
    #endif

    // 초기 홈 (데이터 없을 때) — 무료 분석 배너 + 등록 카드 + 광고 배너
    private var initialContent: some View {
        ScrollView {
            VStack(spacing: .spacing16) {
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
            .padding(.top, .spacing12)
            .padding(.bottom, 92) // 플로팅 하단 바 높이만큼 여백
        }
    }
}

// MARK: - 영수증 등록하기 배너 (파란 배경 + 이미지 하단 중앙)

private struct ReceiptRegisterCard: View {
    var body: some View {
        Color.brandPrimary
            .frame(maxWidth: .infinity, minHeight: 360)
            .overlay(alignment: .bottom) {
                Image("img_receipt_upload")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: .spacing8) {
                    Text("home.card.register.title")
                        .font(.pretendard(.bold, size: 28))
                        .foregroundStyle(Color.colorWhite)
                        .lineSpacing(4)
                    Text("home.card.register.desc")
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color.colorWhite)
                        .lineSpacing(3)
                }
                .padding(.leading, .spacing20)
                .padding(.top, 24)
                .padding(.trailing, .spacing20)
            }
            .clipShape(RoundedRectangle(cornerRadius: .roundedXl))
    }
}

// MARK: - 가전제품 AS 광고 배너 (흰 배경 + 이미지)

private struct RepairServiceCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("home.card.popular.title")
                    .font(.pretendard(.bold, size: 16))
                    .foregroundStyle(Color.brandPrimary)
                    .lineLimit(1)
                Text("home.card.popular.desc")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundStyle(Color.gray500)
                    .lineSpacing(2.5)
            }
            Spacer(minLength: .spacing16)
            Image("img_banner_repair_service")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
        }
        .padding(.horizontal, .spacing20)
        .padding(.vertical, .spacing20)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
        .overlay(
            RoundedRectangle(cornerRadius: .roundedXl)
                .strokeBorder(Color.brandTertiary, lineWidth: 1)
        )
    }
}


