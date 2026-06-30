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
    // OCR 분석 결과 → 결과 화면 표시
    @State private var analysisResult: OcrAnalysis?
    @State private var showResult = false
    @State private var didAutoOpen = false
    // 진입 시 서버 이용 가능 여부 선제 조회
    @State private var isUsageLoading = true
    @State private var serverCanAnalyze = false
    @State private var toast = BoatToastState()
    // [TEST] 파일 업로드 임시 테스트
    @State private var isUploading = false

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
                    uploadTestButton  // [TEST]
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
                        onRecharge: { activeSheet = nil /* TODO: 충전 */ },
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
        // 직접 입력 화면 — 등록한 이미지를 그대로 전달
        .fullScreenCover(isPresented: $showManualInput) {
            ReceiptManualInputView(images: images, onBack: { showManualInput = false })
        }
        // OCR 분석 성공 → 결과 화면
        .fullScreenCover(isPresented: $showResult) {
            if let analysisResult {
                ReceiptAnalysisResultView(result: analysisResult, onBack: { showResult = false })
            }
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
            .overlay(alignment: .topTrailing) {
                Button {
                    images.remove(at: index)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.colorWhite)
                        .frame(width: 22, height: 22)
                        .background(Color.gray500, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
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

    // [TEST] 파일 업로드 임시 테스트 버튼
    private var uploadTestButton: some View {
        let enabled = !images.isEmpty && !isUploading
        return Button {
            Task { await uploadTest() }
        } label: {
            HStack(spacing: .spacing8) {
                if isUploading {
                    ProgressView()
                        .tint(Color.gray500)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "arrow.up.to.line")
                        .frame(width: 20, height: 20)
                        .foregroundStyle(enabled ? Color.gray700 : Color.gray400)
                }
                Text("[TEST] 파일 업로드")
                    .font(.pretendard(.medium, size: 16))
                    .foregroundStyle(enabled ? Color.gray700 : Color.gray400)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.gray100, in: RoundedRectangle(cornerRadius: .roundedXl))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedXl)
                    .stroke(Color.gray300, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
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

    // [TEST] 파일 업로드 임시 테스트
    private func uploadTest() async {
        guard !images.isEmpty else { return }
        isUploading = true
        defer { isUploading = false }
        do {
            let uploaded = try await FileRepository.shared.uploadImages(images)
            let names = uploaded.map { $0.originalName }.joined(separator: ", ")
            toast.showSuccess("업로드 완료 · \(uploaded.count)개\n\(names)")
        } catch {
            toast.showError("업로드 실패: \(error.localizedDescription)")
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
        Task {
            isAnalyzing = true
            defer { isAnalyzing = false }
            do {
                let result = try await OcrRepository.shared.analyze(images)
                // 성공 시 로컬 캐시 토큰 1 차감 (UI에 노출 없이 백그라운드 처리)
                Task.detached { await MainActor.run { CreditStore.shared.deductOne() } }
                analysisResult = result
                showResult = true
            } catch {
                activeSheet = .failed
            }
        }
    }
}

#Preview {
    ReceiptRegisterView(onBack: {})
}
