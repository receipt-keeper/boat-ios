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
            .navigationTitle("common.ocr_test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private var imagePicker: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Label("ocr_test.select_image_button", systemImage: "photo.badge.plus")
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
            Text("ocr_test.selected_image_label")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if !image.isUnderSizeLimit {
                Label("ocr_test.image_size_warning", systemImage: "exclamationmark.triangle.fill")
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
                    Label("ocr_test.run_recognition_button", systemImage: "text.viewfinder")
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
            Text("ocr_test.parse_result_header")
                .font(.subheadline.bold())

            resultRow(label: "ocr_test.field.product_name",  value: receipt.productName,    fallback: String(localized: "ocr_test.fallback.recognition_failed"))
            resultRow(label: "ocr_test.field.brand",         value: receipt.brandName,       fallback: String(localized: "ocr_test.fallback.not_recognized"))
            resultRow(label: "ocr_test.field.purchase_date", value: receipt.purchaseDate.map { dateFormatter.string(from: $0) }, fallback: String(localized: "ocr_test.fallback.today_default"))
            resultRow(label: "ocr_test.field.warranty",      value: receipt.warrantyMonths.map { String(localized: "ocr_test.format.warranty_months \($0)") }, fallback: String(localized: "ocr_test.fallback.warranty_default"))
            resultRow(label: "ocr_test.field.price",         value: receipt.price.map { String(localized: "ocr_test.format.price \($0.formatted())") }, fallback: String(localized: "ocr_test.fallback.not_recognized"))
            resultRow(label: "ocr_test.field.serial",        value: receipt.serialNumber,    fallback: String(localized: "ocr_test.fallback.not_recognized"))
            resultRow(label: "ocr_test.field.category",      value: receipt.category.rawValue, fallback: nil)
            resultRow(label: "ocr_test.field.expiry_date",   value: dateFormatter.string(from: receipt.warrantyExpiryDate), fallback: nil)

            Divider()

            Text("ocr_test.original_text_header \(recognizedLines.count)")
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

    private func resultRow(label: LocalizedStringKey, value: String?, fallback: String?) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Text(value ?? fallback ?? "")
                .font(.subheadline)
                .foregroundStyle(value != nil ? Color.primary : Color.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var rawLinesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ocr_test.recognized_text_header \(recognizedLines.count)")
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
