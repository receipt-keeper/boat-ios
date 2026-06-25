//
//  ReceiptRegisterView.swift
//  BOAT
//
//  영수증 등록 화면 — 무료 분석 배너 + 업로드 슬롯 + 카메라/갤러리 + 분석 시작.
//

import SwiftUI
import PhotosUI

struct ReceiptRegisterView: View {

    let onBack: () -> Void

    private let store = UserStore.shared

    @State private var selectedImage: UIImage?
    @State private var galleryItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraUnavailable = false
    @State private var isAnalyzing = false

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

            Spacer()

            VStack(spacing: .spacing12) {
                outlinedButton(icon: "icCamera", label: "receipt.register.camera") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        cameraUnavailable = true
                    }
                }

                PhotosPicker(selection: $galleryItem, matching: .images) {
                    outlinedButtonLabel(icon: "icImage", label: "receipt.register.gallery")
                }

                analyzeButton
            }
            .padding(.horizontal, .spacing20)
            .padding(.bottom, .spacing12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in selectedImage = image }
                .ignoresSafeArea()
        }
        .onChange(of: galleryItem) { _, item in
            loadGalleryImage(item)
        }
        .alert("카메라를 사용할 수 없습니다.", isPresented: $cameraUnavailable) {
            Button("확인", role: .cancel) {}
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

            imageSlot
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var imageSlot: some View {
        if let image = selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
        } else {
            RoundedRectangle(cornerRadius: .roundedLg)
                .strokeBorder(
                    Color.gray300,
                    style: StrokeStyle(lineWidth: 1, dash: [4])
                )
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.gray400)
                }
        }
    }

    // MARK: - 버튼

    private func outlinedButton(
        icon: String,
        label: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            outlinedButtonLabel(icon: icon, label: label)
        }
        .buttonStyle(.plain)
    }

    private func outlinedButtonLabel(icon: String, label: LocalizedStringKey) -> some View {
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
        let enabled = selectedImage != nil && !isAnalyzing
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

    private func loadGalleryImage(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run { selectedImage = image }
            }
        }
    }

    private func analyze() {
        guard let image = selectedImage else { return }
        isAnalyzing = true
        Task {
            // 기존 OCR 엔진으로 인식 + 파싱 (결과 화면은 추후 연결 — TODO)
            let lines = (try? await OCRService.shared.recognizeOrdered(image: image)) ?? []
            let parsed = ReceiptParser.parse(lines: lines)
            _ = parsed // TODO: 분석 결과 화면으로 이동 / 영수증 등록 플로우
            await MainActor.run { isAnalyzing = false }
        }
    }
}

#Preview {
    ReceiptRegisterView(onBack: {})
}
