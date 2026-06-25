//
//  ReceiptRegisterView.swift
//  BOAT
//
//  영수증 등록 화면 — 무료 분석 배너 + 업로드 그리드(최대 5장) + 카메라/갤러리 + 분석 시작.
//

import SwiftUI
import PhotosUI

struct ReceiptRegisterView: View {

    let onBack: () -> Void

    /// 최대 등록 가능 장수 (Android MAX_PHOTOS와 동일)
    private static let maxPhotos = 5

    private let store = UserStore.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: .spacing8), count: 3)

    @State private var images: [UIImage] = []
    @State private var galleryItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var cameraUnavailable = false
    @State private var showMaxAlert = false
    @State private var isAnalyzing = false

    private var canAddMore: Bool { images.count < Self.maxPhotos }
    private var remainingSlots: Int { max(0, Self.maxPhotos - images.count) }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            VStack(alignment: .leading, spacing: .spacing20) {
                FreeAnalysisBanner(
                    remaining: store.current?.freeAnalysisTokensRemaining ?? 0
                )
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
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in addImages([image]) }
                .ignoresSafeArea()
        }
        .onChange(of: galleryItems) { _, items in
            loadGalleryImages(items)
        }
        .alert("카메라를 사용할 수 없습니다.", isPresented: $cameraUnavailable) {
            Button("common.confirm", role: .cancel) {}
        }
        .alert("receipt.register.max", isPresented: $showMaxAlert) {
            Button("common.confirm", role: .cancel) {}
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

    @ViewBuilder
    private var galleryButton: some View {
        if canAddMore {
            PhotosPicker(
                selection: $galleryItems,
                maxSelectionCount: remainingSlots,
                matching: .images
            ) {
                outlinedLabel(icon: "icImage", label: "receipt.register.gallery")
            }
        } else {
            Button { showMaxAlert = true } label: {
                outlinedLabel(icon: "icImage", label: "receipt.register.gallery")
            }
            .buttonStyle(.plain)
        }
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

    private func analyze() {
        guard !images.isEmpty else { return }
        isAnalyzing = true
        Task {
            // 기존 OCR 엔진으로 인식 + 파싱 (다중 이미지/결과 화면은 추후 연결 — TODO)
            for image in images {
                let lines = (try? await OCRService.shared.recognizeOrdered(image: image)) ?? []
                _ = ReceiptParser.parse(lines: lines)
            }
            await MainActor.run { isAnalyzing = false }
        }
    }
}

#Preview {
    ReceiptRegisterView(onBack: {})
}
