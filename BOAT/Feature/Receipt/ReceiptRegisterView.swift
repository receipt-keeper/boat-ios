//
//  ReceiptRegisterView.swift
//  BOAT
//
//  영수증 등록 화면 — 무료 분석 배너 + 업로드 그리드(최대 5장) + 카메라/갤러리 + 분석 시작.
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

    /// 최대 등록 가능 장수 (Android MAX_PHOTOS와 동일)
    private static let maxPhotos = 5

    private let creditStore = CreditStore.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: .spacing8), count: 3)

    @State private var images: [UIImage] = []
    @State private var galleryItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showGalleryPicker = false
    @State private var cameraUnavailable = false
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

    private var canAddMore: Bool { images.count < Self.maxPhotos }
    private var remainingSlots: Int { max(0, Self.maxPhotos - images.count) }
    /// 남은 무료 분석 토큰 (데이터 없으면 임시 3)
    private var remainingTokens: Int { creditStore.current?.remainingCount ?? 3 }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar

                VStack(alignment: .leading, spacing: .spacing20) {
                    FreeAnalysisBanner(remaining: remainingTokens)
                    uploadedSection
                }
                .padding(.horizontal, .spacing20)
                .padding(.top, .spacing8)

                Spacer(minLength: .spacing20)

                VStack(spacing: .spacing12) {
                    cameraButton
                    galleryButton
                    analyzeButton
                }
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
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCamera = true
                } else {
                    cameraUnavailable = true
                }
            case .gallery:
                showGalleryPicker = true
            }
        }
        .task { await checkUsage() }
        .alert("카메라를 사용할 수 없습니다.", isPresented: $cameraUnavailable) {
            Button("common.confirm", role: .cancel) {}
        }
        .alert("receipt.register.max", isPresented: $showMaxAlert) {
            Button("common.confirm", role: .cancel) {}
        }
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .noToken:
                    NoTokenSheet(
                        onRecharge: {
                            activeSheet = nil
                            Task { await rechargeTestCredits() }
                        },
                        onManualInput: { openManualInput() },
                        onLater: { activeSheet = nil }
                    )
                    .presentationDetents([.height(440)])
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
        .boatToastHost(toast)
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
        HStack {
            Button(action: onBack) {
                Image("icChevronLeft")
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray900)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    // MARK: - 업로드된 영수증

    private var uploadedSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            Text("receipt.register.uploaded")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(Color.gray900)

            if images.isEmpty {
                emptySlot
            } else {
                LazyVGrid(columns: columns, spacing: .spacing8) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        thumbnail(image, index: index)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: .roundedLg)
            .strokeBorder(Color.gray300, style: StrokeStyle(lineWidth: 1, dash: [4]))
            .frame(width: 96, height: 96)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.gray400)
            }
    }

    private func thumbnail(_ image: UIImage, index: Int) -> some View {
        Rectangle()
            .fill(Color.gray100)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
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
                        .background(analyzeFailed ? Color.systemError : Color.gray500, in: Circle())
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

    // MARK: - 버튼

    private var cameraButton: some View {
        Button {
            if !canAddMore {
                showMaxAlert = true
            } else if UIImagePickerController.isSourceTypeAvailable(.camera) {
                showCamera = true
            } else {
                cameraUnavailable = true
            }
        } label: {
            outlinedLabel(icon: "icCamera", label: "receipt.register.camera")
        }
        .buttonStyle(.plain)
    }

    private var galleryButton: some View {
        Button {
            if canAddMore { showGalleryPicker = true } else { showMaxAlert = true }
        } label: {
            outlinedLabel(icon: "icImage", label: "receipt.register.gallery")
        }
        .buttonStyle(.plain)
    }

    private func outlinedLabel(icon: String, label: LocalizedStringKey) -> some View {
        HStack(spacing: .spacing8) {
            Image(icon)
                .renderingMode(.template)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 20, height: 20)
            Text(label)
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color.brandPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
        .overlay(
            RoundedRectangle(cornerRadius: .roundedXl)
                .stroke(Color.brandTertiary, lineWidth: 1)
        )
    }

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

    /// [TEST] 토큰 소진 시트 "N회 무료로 충전하기" — 크레딧 5회 임시 지급 후 이용 가능 여부/잔여 횟수 갱신.
    /// TODO: 정식 충전/이벤트 지급 API가 나오면 ExampleTarget.ocrTestCredits 호출을 교체할 것.
    private func rechargeTestCredits() async {
        guard !isRecharging else { return }
        isRecharging = true
        defer { isRecharging = false }
        do {
            try await APIClient.shared.requestVoid(ExampleTarget.ocrTestCredits)
            // 분석 가능 여부는 usage API로, 배너/게이트에 쓰이는 잔여 횟수는 credits API로 갱신
            await checkUsage()
            try? await CreditRepository.shared.fetchCredits()
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
            activeSheet = .noToken
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
}
