//
//  OCRTestView.swift
//  BOAT
//

import SwiftUI
import PhotosUI

struct OCRTestView: View {

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var recognizedLines: [String] = []
    @State private var parsedReceipt: ParsedReceipt?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imagePicker
                    if let image = selectedImage {
                        selectedImageView(image)
                        runButton
                    }
                    resultSection
                }
                .padding()
            }
            .navigationTitle("OCR 테스트")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private var imagePicker: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Label("영수증 이미지 선택", systemImage: "photo.badge.plus")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: selectedItem) { _, item in
            loadImage(from: item)
        }
    }

    private func selectedImageView(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("선택된 이미지")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if !image.isUnderSizeLimit {
                Label("10MB를 초과하는 이미지입니다.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var runButton: some View {
        Button {
            Task { await runOCR() }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("텍스트 인식 실행", systemImage: "text.viewfinder")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedImage?.isUnderSizeLimit == true ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedImage?.isUnderSizeLimit != true || isLoading)
    }

    @ViewBuilder
    private var resultSection: some View {
        if let error = errorMessage {
            Label(error, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let receipt = parsedReceipt {
            parsedResultView(receipt)
        } else if !recognizedLines.isEmpty {
            rawLinesView
        }
    }

    private func parsedResultView(_ receipt: ParsedReceipt) -> some View {
        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy.MM.dd"
            return f
        }()

        return VStack(alignment: .leading, spacing: 12) {
            Text("파싱 결과")
                .font(.subheadline.bold())

            resultRow(label: "제품명",   value: receipt.productName,    fallback: "(인식 실패 — 직접 입력)")
            resultRow(label: "브랜드",   value: receipt.brandName,       fallback: "(미인식)")
            resultRow(label: "구매일",   value: receipt.purchaseDate.map { dateFormatter.string(from: $0) }, fallback: "오늘 날짜 (기본값)")
            resultRow(label: "보증기간", value: receipt.warrantyMonths.map { "\($0)개월" }, fallback: "12개월 (기본값)")
            resultRow(label: "가격",     value: receipt.price.map { "\($0.formatted())원" }, fallback: "(미인식)")
            resultRow(label: "시리얼",   value: receipt.serialNumber,    fallback: "(미인식)")
            resultRow(label: "대분류",   value: receipt.category.rawValue, fallback: nil)
            resultRow(label: "만료일",   value: dateFormatter.string(from: receipt.warrantyExpiryDate), fallback: nil)

            Divider()

            Text("원본 텍스트 (\(recognizedLines.count)줄)")
                .font(.subheadline.bold())

            ForEach(Array(recognizedLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private func resultRow(label: String, value: String?, fallback: String?) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Text(value ?? fallback ?? "")
                .font(.subheadline)
                .foregroundStyle(value != nil ? .primary : .orange)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var rawLinesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("인식 결과 (\(recognizedLines.count)줄)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(recognizedLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func loadImage(from item: PhotosPickerItem?) {
        recognizedLines = []
        parsedReceipt = nil
        errorMessage = nil
        guard let item else { return }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            await MainActor.run { selectedImage = image }
        }
    }

    @MainActor
    private func runOCR() async {
        guard let image = selectedImage else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            recognizedLines = try await OCRService.shared.recognizeOrdered(image: image)
            parsedReceipt = ReceiptParser.parse(lines: recognizedLines)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    OCRTestView()
}
