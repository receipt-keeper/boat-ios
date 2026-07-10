//
//  ReceiptRegisterView.swift
//  BOAT
//
//  영수증 등록 화면 — 분석횟수 pill + 카메라/갤러리 카드 + 유의사항(접이식) +
//  첨부내역(가로 스크롤, 최대 5장) + 분석 시작. 디자인 확정본 반영.
//

import SwiftUI
import PhotosUI

struct ReceiptRegisterView: View {

    /// 진입 시 자동으로 열 소스 (FAB 카메라/갤러리 선택)
    enum AutoOpen { case camera, gallery }

    let onBack: () -> Void
    var autoOpen: AutoOpen? = nil
    /// 영수증 등록 완료 → 등록 플로우 전체를 닫고 홈으로 복귀
    var onComplete: () -> Void = {}

    @Environment(PermissionManager.self) private var permissions

    /// 최대 등록 가능 장수 (Android MAX_PHOTOS와 동일)
    private static let maxPhotos = 5

    private let creditStore = CreditStore.shared

    @State private var images: [UIImage] = []
    @State private var galleryItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showGalleryPicker = false
    @State private var cameraUnavailable = false
    @State private var showCameraDenied = false
    @State private var showMaxAlert = false
    @State private var isAnalyzing = false
    @State private var activeSheet: AnalysisSheet?
    @State private var showManualInput = false
    @State private var ocrResult: OcrAnalysis?
    @State private var didAutoOpen = false
    // 진입 시 서버 이용 가능 여부 선제 조회
    @State private var isUsageLoading = true
    @State private var serverCanAnalyze = false
    @State private var toast = BoatToastState()
    // [TEST] 토큰 소진 시트의 무료 충전 버튼 — 중복 탭 방지
    @State private var isRecharging = false
    // OCR 실패 시 썸네일 실패 오버레이 표시
    @State private var analyzeFailed = false
    // 토큰 소진 시트 노출 직전 조회한 충전 프로모션 — redeemable이어야 충전 버튼 노출
    @State private var pendingPromo: Promotion?
    // 뒤로가기 시 첨부된 영수증이 있으면 이탈 확인
    @State private var showExitConfirm = false
    // 유의사항 접이식 섹션 — 진입 시 기본 펼침 상태
    @State private var noticeExpanded = true
    // 상단 검색/알림 아이콘
    @State private var showSearch = false
    @State private var showNotifications = false
    // 썸네일 탭 → 전체화면 이미지 뷰어
    @State private var showViewer = false
    @State private var viewerIndex = 0

    private var canAddMore: Bool { images.count < Self.maxPhotos }
    private var remainingSlots: Int { max(0, Self.maxPhotos - images.count) }
    /// 남은 무료 분석 토큰 (데이터 없으면 임시 3)
    private var remainingTokens: Int { creditStore.current?.remainingCount ?? 3 }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headerRow

                        Spacer().frame(height: .spacing20)
                        HStack(spacing: .spacing12) {
                            cameraCard
                            galleryCard
                        }

                        Spacer().frame(height: .spacing12)
                        noticeSection

                        Spacer().frame(height: .spacing24)
                        attachmentsHeader

                        Spacer().frame(height: .spacing12)
                        thumbnailRow
                    }
                    .padding(.horizontal, .spacing20)
                    .padding(.top, .spacing8)
                    .padding(.bottom, .spacing16)
                }

                analyzeButton
                    .padding(.horizontal, .spacing20)
                    .padding(.bottom, .spacing12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.colorWhite)

            if isAnalyzing {
                HomeLoadingView(message: "receipt.analyze.loading")
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.2), value: isAnalyzing)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in addImages([image]) }
                .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $showGalleryPicker,
            selection: $galleryItems,
            maxSelectionCount: max(1, remainingSlots),
            matching: .images
        )
        .onChange(of: galleryItems) { _, items in
            loadGalleryImages(items)
        }
        .onAppear {
            guard !didAutoOpen, let autoOpen else { return }
            didAutoOpen = true
            switch autoOpen {
            case .camera:
                openCamera()
            case .gallery:
                showGalleryPicker = true
            }
        }
        .task { await checkUsage() }
        .alert("카메라를 사용할 수 없습니다.", isPresented: $cameraUnavailable) {
            Button("common.confirm", role: .cancel) {}
        }
        // 카메라 권한 거부 시 — 설정 앱으로 유도
        .alert("permission.camera.denied_title", isPresented: $showCameraDenied) {
            Button("permission.open_settings") { permissions.openSettings() }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("permission.camera.denied_message")
        }
        .alert("receipt.register.max", isPresented: $showMaxAlert) {
            Button("common.confirm", role: .cancel) {}
        }
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .noToken:
                    let canRecharge = pendingPromo?.state == .redeemable
                    NoTokenSheet(
                        canRecharge: canRecharge,
                        onRecharge: {
                            activeSheet = nil
                            Task { await recharge() }
                        },
                        onManualInput: { openManualInput() },
                        onClose: { activeSheet = nil }
                    )
                    .presentationDetents([.height(canRecharge ? 480 : 340)])
                case .failed:
                    AnalysisFailedSheet(
                        onManualInput: { openManualInput() },
                        onRetry: {
                            activeSheet = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { analyze() }
                        }
                    )
                    .presentationDetents([.height(360)])
                }
            }
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.colorWhite)
        }
        // 직접 입력 / OCR 성공 — 이미지 + 분석 결과(있으면 프리필) 전달
        .fullScreenCover(isPresented: $showManualInput) {
            ReceiptManualInputView(
                images: images,
                ocrResult: ocrResult,
                onBack: { showManualInput = false },
                onComplete: {
                    showManualInput = false
                    onComplete()
                }
            )
        }
        // 상단 돋보기/종 아이콘
        .fullScreenCover(isPresented: $showSearch) {
            SearchView(onBack: { showSearch = false })
        }
        .fullScreenCover(isPresented: $showNotifications) {
            NotificationListView(onBack: { showNotifications = false })
        }
        // 썸네일 탭 → 전체화면 이미지 뷰어
        .fullScreenCover(isPresented: $showViewer) {
            ImageViewerScreen(
                items: images.map { .local($0) },
                initialIndex: viewerIndex,
                onClose: { showViewer = false }
            )
        }
        .boatToastHost(toast)
        .boatDialog(
            isPresented: $showExitConfirm,
            title: "dialog.exit_draft.title",
            message: "dialog.exit_draft.message",
            confirmText: "dialog.exit_draft.confirm",
            cancelText: "common.cancel",
            onConfirm: onBack
        )
    }

    /// 시트 닫고 직접 입력 화면 열기
    private func openManualInput() {
        activeSheet = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showManualInput = true
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: .spacing16) {
            Button {
                if images.isEmpty { onBack() } else { showExitConfirm = true }
            } label: {
                Image("icChevronLeft")
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray900)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            headerIcon("icSearch", label: "header.search") { showSearch = true }
            headerIcon("icBell", label: "header.notification") { showNotifications = true }
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    private func headerIcon(_ name: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.gray900)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    // MARK: - 타이틀 + 분석횟수 pill

    private var headerRow: some View {
        HStack(alignment: .center) {
            Text("receipt.add")
                .font(.pretendard(.bold, size: 22))
                .foregroundStyle(Color.gray900)
            Spacer()
            analysisCountPill
        }
    }

    private var analysisCountPill: some View {
        HStack(spacing: .spacing4) {
            Image("icSparkle")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text("receipt.register.analysis_count \(remainingTokens)")
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(Color.brandPrimary)
        }
        .padding(.horizontal, .spacing12)
        .padding(.vertical, .spacing8)
        .background(Color.brandSenary, in: Capsule())
    }

    // MARK: - 카메라/갤러리 카드

    private var cameraCard: some View {
        Button {
            openCamera()
        } label: {
            outlinedCard(icon: "icCamera", label: "receipt.register.camera")
        }
        .buttonStyle(.plain)
    }

    private var galleryCard: some View {
        Button {
            if canAddMore { showGalleryPicker = true } else { showMaxAlert = true }
        } label: {
            outlinedCard(icon: "icImage", label: "receipt.register.gallery")
        }
        .buttonStyle(.plain)
    }

    private func outlinedCard(icon: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: .spacing12) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 32, height: 32)
            Text(label)
                .font(.pretendard(.medium, size: 15))
                .foregroundStyle(Color.brandPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
        .overlay(
            RoundedRectangle(cornerRadius: .roundedXl)
                .stroke(Color.brandTertiary, lineWidth: 1)
        )
    }

    // MARK: - 유의사항 (접이식)

    private var noticeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { noticeExpanded.toggle() }
            } label: {
                HStack(spacing: .spacing8) {
                    noticeIcon
                    Text("receipt.notice.title")
                        .font(.pretendard(.medium, size: 15))
                        .foregroundStyle(Color.gray900)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.gray500)
                        .rotationEffect(.degrees(noticeExpanded ? 180 : 0))
                }
                .padding(.horizontal, .spacing16)
                .frame(height: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if noticeExpanded {
                Rectangle().fill(Color.gray200).frame(height: 1)
                    .padding(.horizontal, .spacing16)

                VStack(alignment: .leading, spacing: .spacing20) {
                    noticeBullet(
                        iconAsset: "icon_images_upload",
                        pre: "receipt.notice.bullet1_pre",
                        highlight: "receipt.notice.bullet1_highlight",
                        post: "receipt.notice.bullet1_post"
                    )
                    noticeBullet(
                        systemIcon: "square.and.arrow.up",
                        pre: "receipt.notice.bullet2_pre",
                        highlight: "receipt.notice.bullet2_highlight",
                        post: "receipt.notice.bullet2_post"
                    )
                    noticeBullet(
                        systemIcon: "folder",
                        pre: nil,
                        highlight: "receipt.notice.bullet3_highlight",
                        post: "receipt.notice.bullet3_post"
                    )
                }
                .padding(.spacing16)
            }
        }
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
        .overlay(
            RoundedRectangle(cornerRadius: .roundedLg)
                .stroke(Color.gray300, lineWidth: 1)
        )
    }

    private var noticeIcon: some View {
        Circle()
            .fill(Color.brandPrimary)
            .frame(width: 20, height: 20)
            .overlay {
                Image(systemName: "info")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.colorWhite)
            }
    }

    private func noticeBullet(
        iconAsset: String? = nil,
        systemIcon: String? = nil,
        pre: LocalizedStringKey?,
        highlight: LocalizedStringKey,
        post: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: .spacing12) {
            bulletIcon(iconAsset: iconAsset, systemIcon: systemIcon)
                .frame(width: 22, height: 22)

            (
                (pre.map { Text($0) } ?? Text(""))
                    .foregroundStyle(Color.gray700)
                + Text(highlight)
                    .foregroundStyle(Color.brandPrimary)
                    .fontWeight(.semibold)
                + Text(post)
                    .foregroundStyle(Color.gray700)
            )
            .font(.pretendard(.regular, size: 14))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func bulletIcon(iconAsset: String?, systemIcon: String?) -> some View {
        if let iconAsset {
            Image(iconAsset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.brandSecondary)
        } else if let systemIcon {
            Image(systemName: systemIcon)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.brandSecondary)
        }
    }

    // MARK: - 영수증 첨부내역

    private var attachmentsHeader: some View {
        HStack {
            Text("receipt.register.attachments")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)
            Spacer()
            Text("\(images.count)/\(Self.maxPhotos)")
                .font(.pretendard(.bold, size: 15))
                .foregroundStyle(Color.brandPrimary)
        }
    }

    private var thumbnailRow: some View {
        Group {
            if images.isEmpty {
                emptySlot
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacing12) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            thumbnail(image, index: index)
                        }
                    }
                }
            }
        }
    }

    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: .roundedLg)
            .strokeBorder(Color.gray300, style: StrokeStyle(lineWidth: 1, dash: [4]))
            .frame(width: 100, height: 100)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.gray400)
            }
    }

    private func thumbnail(_ image: UIImage, index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
            .contentShape(RoundedRectangle(cornerRadius: .roundedLg))
            .onTapGesture {
                viewerIndex = index
                showViewer = true
            }
            .overlay {
                if analyzeFailed {
                    failOverlay
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    images.remove(at: index)
                    analyzeFailed = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.colorWhite)
                        .frame(width: 22, height: 22)
                        .background(analyzeFailed ? Color.systemError : Color.gray500.opacity(0.8), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
    }

    private var failOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: .roundedLg))

            VStack(spacing: .spacing4) {
                ZStack {
                    Circle()
                        .stroke(Color.systemError, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    Text("!")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.systemError)
                }

                Text("다시 업로드해 주세요")
                    .font(.pretendard(.medium, size: 9))
                    .foregroundStyle(Color.systemError)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - 분석 시작 버튼

    private var analyzeButton: some View {
        let enabled = !images.isEmpty && !isAnalyzing
        return Button {
            analyze()
        } label: {
            Text("receipt.register.analyze")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(enabled ? Color.colorWhite : Color.gray500)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    enabled ? Color.brandPrimary : Color.gray200,
                    in: RoundedRectangle(cornerRadius: .roundedXl)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Actions

    /// 카메라 실행 — 촬영 버튼 탭 시점에 권한 확인/요청 (App Store 심사 가이드 준수).
    private func openCamera() {
        guard canAddMore else { showMaxAlert = true; return }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraUnavailable = true // 시뮬레이터 등 카메라 미탑재
            return
        }
        Task {
            switch permissions.cameraStatus {
            case .granted:
                showCamera = true
            case .notDetermined:
                // 첫 진입 — 이 시점에만 시스템 권한 다이얼로그 노출
                let status = await permissions.requestCameraPermission()
                if status == .granted { showCamera = true }
                else if status == .denied { showCameraDenied = true }
            case .denied:
                showCameraDenied = true
            }
        }
    }

    /// 이미지 추가 (최대 5장 cap)
    private func addImages(_ new: [UIImage]) {
        guard !new.isEmpty else { return }
        let slots = remainingSlots
        guard slots > 0 else { showMaxAlert = true; return }
        images.append(contentsOf: new.prefix(slots))
        analyzeFailed = false
    }

    private func loadGalleryImages(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            var loaded: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loaded.append(image)
                }
            }
            await MainActor.run {
                addImages(loaded)
                galleryItems = [] // 다음 선택을 위해 초기화
            }
        }
    }

    private func checkUsage() async {
        do {
            let usage = try await UsageRepository.shared.fetchUsage()
            serverCanAnalyze = usage.canAnalyze
        } catch {
            serverCanAnalyze = false
        }
        isUsageLoading = false
    }

    /// 토큰 소진 시트 노출 전 프로모션 상태를 미리 조회 — redeemable일 때만 충전 버튼을 보여준다.
    private func presentNoTokenSheet() async {
        pendingPromo = try? await PromotionRepository.shared.fetchOcrRecharge()
        activeSheet = .noToken
    }

    /// 토큰 소진 시트 "N회 무료로 충전하기" — 월간 충전 프로모션 조회 후 수령 가능하면 크레딧 수령.
    /// 수령 성공 시 응답 balance로 잔여 크레딧을 즉시 반영하고, 이용 가능 여부(canAnalyze)를 재확인한다.
    private func recharge() async {
        guard !isRecharging else { return }
        isRecharging = true
        defer { isRecharging = false }
        do {
            let promo = try await PromotionRepository.shared.fetchOcrRecharge()
            switch promo.state {
            case .redeemable:
                guard let promotionId = promo.promotionId else {
                    toast.showError(String(localized: "receipt.register.network_error"))
                    return
                }
                let result = try await PromotionRepository.shared.redeem(promotionId: promotionId)
                // 수령 응답 balance.remainingCount를 최신 잔여 크레딧으로 반영
                if let balance = result.balance {
                    CreditStore.shared.apply(
                        remainingCount: balance.remainingCount,
                        totalGrantedCount: balance.totalGrantedCount
                    )
                }
                let granted = result.benefit?.amount ?? promo.benefit?.amount ?? 5
                toast.show(String(localized: "receipt.recharge.success \(granted)"), type: .info)
                await checkUsage() // canAnalyze 재확인
            case .alreadyRedeemed:
                toast.show(String(localized: "receipt.recharge.already"), type: .info)
            case .unavailable, .expired, .exhausted, .unknown:
                toast.show(String(localized: "receipt.recharge.unavailable"), type: .info)
            }
        } catch let APIError.server(statusCode, _) where statusCode == 409 {
            // 이미 이번 달 수령함(경합/직접 호출) — 안내 후 상태만 재확인
            toast.show(String(localized: "receipt.recharge.already"), type: .info)
            await checkUsage()
        } catch {
            toast.showError(String(localized: "receipt.register.network_error"))
        }
    }

    private func analyze() {
        guard !images.isEmpty else { return }

        // 1) 이용 가능 여부 조회 중이면 네트워크 안내 토스트
        guard !isUsageLoading else {
            toast.showError(String(localized: "receipt.register.network_error"))
            return
        }

        // 2) 서버 canAnalyze + 로컬 토큰 AND 조건
        guard serverCanAnalyze && remainingTokens > 0 else {
            Task { await presentNoTokenSheet() }
            return
        }

        // 3) OCR 분석 API 호출 → 성공 시 결과 화면, 실패 시 실패 시트
        analyzeFailed = false
        Task {
            isAnalyzing = true
            defer { isAnalyzing = false }
            do {
                let result = try await OcrRepository.shared.analyze(images)
                // 성공 시 로컬 캐시 토큰 1 차감 (UI에 노출 없이 백그라운드 처리)
                Task.detached { await MainActor.run { CreditStore.shared.deductOne() } }
                ocrResult = result
                showManualInput = true
            } catch {
                analyzeFailed = true
                activeSheet = .failed
            }
        }
    }
}

#Preview {
    ReceiptRegisterView(onBack: {})
        .environment(PermissionManager())
}
