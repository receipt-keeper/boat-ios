//
//  ReceiptManualInputView.swift
//  BOAT
//
//  영수증 정보 입력 화면.
//  OCR 성공 시 분석 결과 프리필, 직접 입력 시 빈 폼으로 진입.
//  Android ReceiptManualInputScreen 대응.
//  필수(*): 제품명 / 구매일 / 무상 AS 만료기간 → 모두 채워야 등록 버튼 활성화.
//

import SwiftUI
import PhotosUI

struct ReceiptManualInputView: View {

    let onBack: () -> Void
    /// 영수증 등록 성공 → 홈으로 복귀 처리 (상위에서 등록 플로우 전체를 닫음)
    var onComplete: () -> Void = {}

    private static let maxPhotos = 5
    private static let warrantyOptions: [LocalizedStringKey] = [
        "manual.warranty_6m", "manual.warranty_1y", "manual.warranty_2y", "manual.warranty_3y", "manual.warranty_custom",
    ]

    @State private var images: [UIImage]
    @State private var currentImagePage = 0
    @State private var galleryItems: [PhotosPickerItem] = []

    @State private var selectedCategory: DeviceCategory?
    @State private var productName = ""
    @State private var purchaseDate = ""
    @State private var selectedWarranty: Int?
    @State private var customMonthsText = ""
    @State private var customIsYears = false
    @State private var memo = ""
    @State private var brand = ""
    @State private var price = ""
    @State private var serial = ""
    @State private var keepReceipt = true
    @State private var showDatePicker = false
    @State private var isSubmitting = false
    @State private var toast = BoatToastState()

    init(images: [UIImage], ocrResult: OcrAnalysis? = nil, onBack: @escaping () -> Void, onComplete: @escaping () -> Void = {}) {
        _images = State(initialValue: images)
        self.onBack = onBack
        self.onComplete = onComplete

        guard let ocr = ocrResult else { return }

        _productName = State(initialValue: ocr.itemName ?? "")
        _brand = State(initialValue: ocr.brandName ?? "")

        if let dateStr = ocr.paymentDate {
            let parts = dateStr.split(separator: "-").map(String.init)
            if parts.count == 3 {
                _purchaseDate = State(initialValue: parts.joined(separator: "."))
            }
        }

        if let amount = ocr.totalAmount {
            _price = State(initialValue: "\(amount)")
        }

        if let cat = ocr.category {
            _selectedCategory = State(initialValue: DeviceCategory(rawValue: cat))
        }

        if let months = ocr.periodMonths {
            switch months {
            case 6:  _selectedWarranty = State(initialValue: 0)
            case 12: _selectedWarranty = State(initialValue: 1)
            case 24: _selectedWarranty = State(initialValue: 2)
            case 36: _selectedWarranty = State(initialValue: 3)
            default:
                _selectedWarranty = State(initialValue: 4)
                _customMonthsText = State(initialValue: "\(months)")
            }
        }
    }

    // MARK: - Computed

    private var remainingSlots: Int { max(0, Self.maxPhotos - images.count) }

    private var totalWarrantyMonths: Int? {
        switch selectedWarranty {
        case 0: return 6
        case 1: return 12
        case 2: return 24
        case 3: return 36
        case 4:
            guard let n = Int(customMonthsText), n > 0 else { return nil }
            return customIsYears ? n * 12 : n
        default: return nil
        }
    }

    private var expiresOnDisplay: String? {
        guard let months = totalWarrantyMonths, !purchaseDate.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        guard let start = formatter.date(from: purchaseDate) else { return nil }
        guard let expiry = Calendar.current.date(byAdding: .month, value: months, to: start) else { return nil }
        return formatter.string(from: expiry)
    }

    private var canSubmit: Bool {
        !productName.trimmingCharacters(in: .whitespaces).isEmpty
            && !purchaseDate.isEmpty
            && totalWarrantyMonths != nil
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionTitle("manual.image_section")
                        Spacer().frame(height: .spacing12)
                        imagePager

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

                        Spacer().frame(height: .spacing24)
                        submitButton

                        Spacer().frame(height: .spacing16)
                    }
                    .padding(.horizontal, .spacing20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray50)

            if isSubmitting {
                HomeLoadingView(message: "receipt.register.loading")
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.2), value: isSubmitting)
        .onChange(of: galleryItems) { _, items in loadGalleryImages(items) }
        .sheet(isPresented: $showDatePicker) {
            PurchaseDatePickerSheet(
                onConfirm: { purchaseDate = $0; showDatePicker = false },
                onCancel:  { showDatePicker = false }
            )
            .presentationDetents([.medium])
        }
        .boatToastHost(toast)
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

    // MARK: - 이미지 페이저

    @ViewBuilder
    private var imagePager: some View {
        if images.isEmpty {
            RoundedRectangle(cornerRadius: .roundedXl)
                .strokeBorder(Color.gray300, style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(height: 220)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.gray400)
                }
        } else {
            TabView(selection: $currentImagePage) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)
            .background(Color.gray100)
            .clipShape(RoundedRectangle(cornerRadius: .roundedXl))
            .overlay(alignment: .bottomTrailing) {
                if images.count > 1 {
                    Text("\(currentImagePage + 1) / \(images.count)")
                        .font(.pretendard(.medium, size: 12))
                        .foregroundStyle(Color.colorWhite)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.5), in: Capsule())
                        .padding(12)
                }
            }
        }
    }

    // MARK: - 메인 입력 카드

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 카테고리 칩
            HStack(spacing: .spacing8) {
                ForEach(DeviceCategory.allCases, id: \.self) { category in
                    categoryItem(category)
                }
            }

            Spacer().frame(height: .spacing20)
            BoatInputField(
                text: $productName,
                label: "manual.product_name",
                required: true,
                placeholder: "manual.product_name_hint"
            )

            Spacer().frame(height: .spacing16)
            fieldLabel("manual.purchase_date", required: true)
            Spacer().frame(height: .spacing8)
            fieldBox(onTap: { showDatePicker = true }) {
                HStack(spacing: .spacing8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.gray400)
                    Text(purchaseDate.isEmpty ? String(localized: "manual.purchase_date_hint") : purchaseDate)
                        .font(.pretendard(.regular, size: 15))
                        .foregroundStyle(purchaseDate.isEmpty ? Color.gray400 : Color.gray900)
                }
            }

            Spacer().frame(height: .spacing16)
            fieldLabel("manual.warranty", required: true)
            Spacer().frame(height: .spacing8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing8) {
                    ForEach(Array(Self.warrantyOptions.enumerated()), id: \.offset) { index, label in
                        warrantyChip(label, selected: selectedWarranty == index) {
                            selectedWarranty = index
                            if index != 4 {
                                customMonthsText = ""
                                customIsYears = false
                            }
                        }
                    }
                }
            }

            // 직접입력 모드 — 숫자 입력 + 개월/년 단위 칩
            if selectedWarranty == 4 {
                Spacer().frame(height: .spacing8)
                HStack(spacing: .spacing8) {
                    TextField("0", text: $customMonthsText)
                        .keyboardType(.numberPad)
                        .font(.pretendard(.regular, size: 15))
                        .foregroundStyle(Color.gray900)
                        .padding(.horizontal, .spacing12)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
                        .overlay(
                            RoundedRectangle(cornerRadius: .roundedLg)
                                .stroke(Color.gray300, lineWidth: 1)
                        )
                    customUnitChip("개월", selected: !customIsYears) { customIsYears = false }
                    customUnitChip("년", selected: customIsYears)    { customIsYears = true  }
                }
            }

            // 만료일 정보 박스 — 보증기간+구매일 모두 유효할 때
            if let expiresOn = expiresOnDisplay {
                Spacer().frame(height: .spacing8)
                HStack(spacing: .spacing8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandPrimary)
                    Text("무상 AS 만료일 \(expiresOn)")
                        .font(.pretendard(.semibold, size: 13))
                        .foregroundStyle(Color.brandPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .spacing12)
                .padding(.vertical, 10)
                .background(Color.brandSenary, in: RoundedRectangle(cornerRadius: .roundedLg))
            } else if needsWarrantyHint {
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

    private var needsWarrantyHint: Bool {
        if selectedWarranty == nil { return true }
        if selectedWarranty == 4 {
            let n = Int(customMonthsText) ?? 0
            return n <= 0
        }
        return false
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
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(Color.gray300, lineWidth: 1)
            )
            Text("manual.memo_counter")
                .font(.pretendard(.regular, size: 12))
                .foregroundStyle(Color.gray400)
        }
    }

    // MARK: - 보증 정보 카드

    private var warrantyInfoCard: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            BoatInputField(text: $brand, label: "manual.brand", placeholder: "manual.brand_hint")
            BoatInputField(
                text: Binding(get: { price }, set: { price = $0.filter(\.isNumber) }),
                label: "manual.price",
                placeholder: "manual.price_hint",
                keyboard: .numberPad
            )
            BoatInputField(text: $serial, label: "manual.serial", placeholder: "manual.serial_hint")
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

            Button { keepReceipt.toggle() } label: {
                HStack(spacing: .spacing8) {
                    Image(systemName: keepReceipt ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundStyle(keepReceipt ? Color.brandPrimary : Color.gray300)
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
        let enabled = canSubmit && !isSubmitting
        return Button {
            submit()
        } label: {
            Text("manual.submit")
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
                .foregroundStyle(Color.gray600)
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
            .frame(height: 52)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
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
                    .overlay {
                        Image(category.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                    }
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

    private func customUnitChip(_ label: String, selected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(label)
                .font(.pretendard(.medium, size: 14))
                .foregroundStyle(selected ? Color.brandPrimary : Color.gray700)
                .frame(width: 56, height: 44)
                .background(selected ? Color.brandQuinary : Color.gray100, in: RoundedRectangle(cornerRadius: .roundedLg))
                .overlay(
                    RoundedRectangle(cornerRadius: .roundedLg)
                        .stroke(selected ? Color.brandPrimary : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    /// "yyyy.MM.dd" → "yyyy-MM-dd" (서버 전송 포맷)
    private var apiPaymentDate: String? {
        guard !purchaseDate.isEmpty else { return nil }
        return purchaseDate.replacingOccurrences(of: ".", with: "-")
    }

    /// 영수증 등록: 파일 업로드 → 생성 API → 로컬 저장 → 홈 복귀. 실패 시 Toast.
    private func submit() {
        guard canSubmit, !isSubmitting else { return }

        let fields = ReceiptCreateFields(
            itemName: productName.trimmingCharacters(in: .whitespaces),
            brandName: brand.trimmingCharacters(in: .whitespaces),
            paymentLocation: nil,
            paymentDate: apiPaymentDate,
            totalAmount: Int(price),
            periodMonths: totalWarrantyMonths,
            category: selectedCategory?.rawValue,
            subCategory: nil,
            memo: memo.trimmingCharacters(in: .whitespaces),
            requiresPhysicalReceipt: keepReceipt
        )
        let imagesToUpload = images

        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                _ = try await ReceiptRepository.shared.createReceipt(images: imagesToUpload, fields: fields)
                onComplete()
            } catch {
                toast.showError(String(localized: "receipt.register.fail"))
            }
        }
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
                images.append(contentsOf: loaded.prefix(remainingSlots))
                galleryItems = []
            }
        }
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
