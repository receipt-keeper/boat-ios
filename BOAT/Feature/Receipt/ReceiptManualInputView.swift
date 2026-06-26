//
//  ReceiptManualInputView.swift
//  BOAT
//
//  영수증 직접 입력 화면 (OCR 실패/토큰 소진 시 진입).
//  앞 화면에서 등록한 이미지를 그대로 받아 표시. Android ReceiptManualInputScreen 대응.
//  필수(*): 제품명 / 구매일 / 무상 AS 만료기간 → 모두 채워야 등록 버튼 활성화.
//

import SwiftUI
import PhotosUI

struct ReceiptManualInputView: View {

    let onBack: () -> Void

    private static let maxPhotos = 5
    private static let warrantyOptions: [LocalizedStringKey] = [
        "manual.warranty_6m", "manual.warranty_1y", "manual.warranty_2y", "manual.warranty_3y", "manual.warranty_custom",
    ]

    @State private var images: [UIImage]
    @State private var galleryItems: [PhotosPickerItem] = []

    @State private var selectedCategory: DeviceCategory?
    @State private var productName = ""
    @State private var purchaseDate = ""
    @State private var selectedWarranty: Int?
    @State private var memo = ""
    @State private var brand = ""
    @State private var price = ""
    @State private var serial = ""
    @State private var keepReceipt = true
    @State private var showDatePicker = false

    init(images: [UIImage], onBack: @escaping () -> Void) {
        _images = State(initialValue: images)
        self.onBack = onBack
    }

    private var canSubmit: Bool {
        !productName.trimmingCharacters(in: .whitespaces).isEmpty
            && !purchaseDate.isEmpty
            && selectedWarranty != nil
    }
    private var remainingSlots: Int { max(0, Self.maxPhotos - images.count) }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // ── 등록된 이미지 확인 ──
                    sectionTitle("manual.image_section")
                    Spacer().frame(height: .spacing12)
                    imageRow

                    Spacer().frame(height: .spacing20)
                    mainCard

                    Spacer().frame(height: .spacing20)
                    sectionTitle("manual.warranty_section")
                    Spacer().frame(height: .spacing12)
                    warrantyInfoCard

                    Spacer().frame(height: .spacing20)
                    sectionTitle("manual.as_section")
                    Spacer().frame(height: .spacing12)
                    asGuideCard

                    Spacer().frame(height: .spacing16)
                }
                .padding(.horizontal, .spacing20)
            }

            submitButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray50)
        .onChange(of: galleryItems) { _, items in loadGalleryImages(items) }
        .sheet(isPresented: $showDatePicker) {
            PurchaseDatePickerSheet(onConfirm: { purchaseDate = $0; showDatePicker = false },
                                    onCancel: { showDatePicker = false })
                .presentationDetents([.medium])
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

    // MARK: - 이미지 행

    private var imageRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing12) {
                if images.count < Self.maxPhotos {
                    if remainingSlots > 0 {
                        PhotosPicker(selection: $galleryItems, maxSelectionCount: remainingSlots, matching: .images) {
                            addImageTile
                        }
                    }
                }
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    imageThumbnail(image, index: index)
                }
            }
        }
    }

    private var addImageTile: some View {
        VStack(spacing: 2) {
            Text("+")
                .font(.pretendard(.bold, size: 28))
                .foregroundStyle(Color.brandPrimary)
            Text("manual.image_add")
                .font(.pretendard(.regular, size: 13))
                .foregroundStyle(Color.brandPrimary)
        }
        .frame(width: 100, height: 100)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
        .overlay(
            RoundedRectangle(cornerRadius: .roundedXl)
                .stroke(Color.brandQuinary, lineWidth: 1)
        )
    }

    private func imageThumbnail(_ image: UIImage, index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: .roundedXl))
            .overlay(alignment: .topTrailing) {
                Button {
                    images.remove(at: index)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.colorWhite)
                        .frame(width: 22, height: 22)
                        .background(Color.black.opacity(0.4), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
    }

    // MARK: - 메인 입력 카드

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 카테고리
            HStack(spacing: .spacing8) {
                ForEach(DeviceCategory.allCases, id: \.self) { category in
                    categoryItem(category)
                }
            }

            Spacer().frame(height: .spacing20)
            fieldLabel("manual.product_name", required: true)
            Spacer().frame(height: .spacing8)
            FormTextField(text: $productName, hint: "manual.product_name_hint")

            Spacer().frame(height: .spacing16)
            fieldLabel("manual.purchase_date", required: true)
            Spacer().frame(height: .spacing8)
            fieldBox(onTap: { showDatePicker = true }) {
                Text(purchaseDate.isEmpty ? String(localized: "manual.purchase_date_hint") : purchaseDate)
                    .font(.pretendard(.regular, size: 15))
                    .foregroundStyle(purchaseDate.isEmpty ? Color.gray400 : Color.gray900)
            }

            Spacer().frame(height: .spacing16)
            fieldLabel("manual.warranty", required: true)
            Spacer().frame(height: .spacing8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing8) {
                    ForEach(Array(Self.warrantyOptions.enumerated()), id: \.offset) { index, label in
                        warrantyChip(label, selected: selectedWarranty == index) {
                            selectedWarranty = index
                        }
                    }
                }
            }
            if selectedWarranty == nil {
                Spacer().frame(height: .spacing8)
                Text("manual.warranty_hint")
                    .font(.pretendard(.semibold, size: 13))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, .spacing12)
                    .padding(.vertical, 10)
                    .background(Color.brandSenary, in: RoundedRectangle(cornerRadius: .roundedLg))
            }

            Spacer().frame(height: .spacing16)
            fieldLabel("manual.memo", required: false)
            Spacer().frame(height: .spacing8)
            memoField
        }
        .padding(.spacing16)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    private var memoField: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if memo.isEmpty {
                    Text("manual.memo_hint")
                        .font(.pretendard(.regular, size: 15))
                        .foregroundStyle(Color.gray400)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                }
                TextEditor(text: Binding(
                    get: { memo },
                    set: { memo = String($0.prefix(100)) }
                ))
                .font(.pretendard(.regular, size: 15))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(height: 120)
            }
            .overlay(
                RoundedRectangle(cornerRadius: .roundedXl)
                    .stroke(Color.gray300, lineWidth: 1)
            )
            Text("manual.memo_counter")
                .font(.pretendard(.regular, size: 12))
                .foregroundStyle(Color.gray400)
        }
    }

    // MARK: - 보증 정보 카드

    private var warrantyInfoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            fieldLabel("manual.brand", required: false)
            Spacer().frame(height: .spacing8)
            FormTextField(text: $brand, hint: "manual.brand_hint")

            Spacer().frame(height: .spacing16)
            fieldLabel("manual.price", required: false)
            Spacer().frame(height: .spacing8)
            FormTextField(text: $price, hint: "manual.price_hint", keyboard: .numberPad)

            Spacer().frame(height: .spacing16)
            fieldLabel("manual.serial", required: false)
            Spacer().frame(height: .spacing8)
            FormTextField(text: $serial, hint: "manual.serial_hint")
        }
        .padding(.spacing16)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    // MARK: - 무상 AS 안내 카드

    private var asGuideCard: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            Text("manual.as_guide")
                .font(.pretendard(.regular, size: 13))
                .foregroundStyle(Color.gray600)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                keepReceipt.toggle()
            } label: {
                HStack(spacing: .spacing8) {
                    Image(systemName: keepReceipt ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundStyle(keepReceipt ? Color.gray400 : Color.gray300)
                    Text("manual.as_keep_receipt")
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color.gray700)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    // MARK: - 등록 버튼

    private var submitButton: some View {
        Button {
            // TODO: 영수증 정보 등록 API
        } label: {
            Text("manual.submit")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(canSubmit ? Color.colorWhite : Color.gray500)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    canSubmit ? Color.brandPrimary : Color.gray200,
                    in: RoundedRectangle(cornerRadius: .roundedXl)
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .padding(.horizontal, .spacing20)
        .padding(.vertical, .spacing12)
    }

    // MARK: - 작은 컴포넌트

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.pretendard(.bold, size: 18))
            .foregroundStyle(Color.gray900)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fieldLabel(_ key: LocalizedStringKey, required: Bool) -> some View {
        HStack(spacing: 0) {
            Text(key)
                .font(.pretendard(.medium, size: 14))
                .foregroundStyle(Color.gray900)
            if required {
                Text(" *")
                    .font(.pretendard(.medium, size: 14))
                    .foregroundStyle(Color.systemError)
            }
        }
    }

    private func fieldBox(onTap: @escaping () -> Void, @ViewBuilder content: () -> some View) -> some View {
        Button(action: onTap) {
            HStack {
                content()
                Spacer()
            }
            .padding(.horizontal, .spacing16)
            .frame(height: 56)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedXl)
                    .stroke(Color.gray300, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func categoryItem(_ category: DeviceCategory) -> some View {
        let selected = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: .roundedXl)
                    .fill(selected ? Color.brandQuinary : Color.gray100)
                    .frame(height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: .roundedXl)
                            .stroke(selected ? Color.brandPrimary : Color.clear, lineWidth: 1.5)
                    )
                Text(category.rawValue)
                    .font(.pretendard(.regular, size: 11))
                    .foregroundStyle(selected ? Color.brandPrimary : Color.gray600)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func warrantyChip(_ label: LocalizedStringKey, selected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(label)
                .font(.pretendard(.medium, size: 13))
                .foregroundStyle(selected ? Color.brandPrimary : Color.gray700)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    Capsule().stroke(selected ? Color.brandPrimary : Color.gray300, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

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
                images.append(contentsOf: loaded.prefix(remainingSlots))
                galleryItems = []
            }
        }
    }
}

// MARK: - 폼 텍스트 필드 (포커스 시 테두리 강조)

private struct FormTextField: View {
    @Binding var text: String
    let hint: LocalizedStringKey
    var keyboard: UIKeyboardType = .default
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $text, prompt: Text(hint).foregroundStyle(Color.gray400))
            .font(.pretendard(.regular, size: 15))
            .keyboardType(keyboard)
            .focused($focused)
            .padding(.horizontal, .spacing16)
            .frame(height: 56)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedXl)
                    .stroke(focused ? Color.brandPrimary : Color.gray300, lineWidth: 1)
            )
    }
}

// MARK: - 구매일 DatePicker 시트

private struct PurchaseDatePickerSheet: View {
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    @State private var date = Date()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("common.cancel", action: onCancel)
                    .foregroundStyle(Color.gray600)
                Spacer()
                Button("common.confirm") {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy.MM.dd"
                    onConfirm(f.string(from: date))
                }
                .foregroundStyle(Color.brandPrimary)
                .fontWeight(.semibold)
            }
            .font(.pretendard(.medium, size: 15))
            .padding(.horizontal, .spacing20)
            .padding(.vertical, .spacing16)

            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color.brandPrimary)
                .padding(.horizontal, .spacing12)

            Spacer()
        }
        .presentationBackground(Color.colorWhite)
    }
}

#Preview {
    ReceiptManualInputView(images: [], onBack: {})
}
