//
//  ReceiptEditView.swift
//  BOAT
//
//  영수증 상세 화면의 케밥 → "수정하기"로 진입하는 수정 화면. 디자인 확정본 반영.
//  - 카테고리: 대분류 드롭다운 + 소분류 칩 (ReceiptManualInputView와 동일 패턴)
//  - 제품명/구매일/무상 AS 만료기간/메모: 글자 수 제한 초과 시 에러 테두리+안내문 (자르지 않음)
//  - 실물 영수증 보관 여부: 라디오 / 보증 정보: 브랜드·가격·시리얼(도움말 아이콘)
//  - 원본 영수증: 추가하기 탭 시 네이티브 액션시트(카메라로 촬영하기/갤러리에서 불러오기/닫기)
//  - 수정 완료: 신규 이미지만 업로드 → 유지할 기존 fileId와 합쳐 PATCH /api/v1/receipts/{id}
//    (첨부 이미지는 1장 이상 5장 이하 유지)
//

import SwiftUI
import PhotosUI

struct ReceiptEditView: View {

    let onBack: () -> Void
    /// 수정 완료 콜백 — 상위(상세)에서 재조회 + 수정 완료 토스트 처리
    var onUpdated: () -> Void = {}

    @Environment(PermissionManager.self) private var permissions

    private let receiptId: String
    private static let maxPhotos = 5
    private static let minPhotos = 1
    private static let warrantyOptions: [LocalizedStringKey] = [
        "manual.warranty_6m", "manual.warranty_1y", "manual.warranty_2y", "manual.warranty_3y", "manual.warranty_custom",
    ]
    private static let productNameLimit = 50
    private static let memoLimit = 100
    private static let brandLimit = 50
    private static let serialLimit = 30

    // 카테고리
    @State private var selectedCategory: DeviceCategory
    @State private var selectedSubcategory: String?
    @State private var categoryExpanded = false

    // 제품 정보
    @State private var productName: String
    @State private var purchaseDate: String
    @State private var selectedWarranty: Int?
    @State private var customMonthsText = ""
    @State private var customIsYears = false
    @State private var memo: String
    @State private var showDatePicker = false

    // 실물 영수증 보관 여부
    @State private var physicalReceipt: Bool?

    // 보증 정보
    @State private var brand: String
    @State private var price: String
    @State private var serial: String

    // 원본 영수증 — 기존 첨부(플레이스홀더, 파일 서빙 URL 미확정) + 신규 추가(UIImage)
    @State private var existingFileIds: [String]
    @State private var newImages: [UIImage] = []
    @State private var galleryItems: [PhotosPickerItem] = []
    @State private var showAddMenu = false
    @State private var showCamera = false
    @State private var showGalleryPicker = false
    @State private var cameraUnavailable = false
    @State private var showCameraDenied = false

    @State private var isSubmitting = false
    @State private var toast = BoatToastState()

    init(receipt: Receipt, onBack: @escaping () -> Void, onUpdated: @escaping () -> Void = {}) {
        self.receiptId = receipt.receiptId
        self.onBack = onBack
        self.onUpdated = onUpdated

        let category = DeviceCategory.from(serverValue: receipt.category) ?? .kitchen
        _selectedCategory = State(initialValue: category)
        _selectedSubcategory = State(initialValue: Self.matchSubcategory(receipt.subCategory, in: category))

        _productName = State(initialValue: receipt.itemName)
        _brand = State(initialValue: receipt.brandName ?? "")
        _serial = State(initialValue: receipt.serialNumber ?? "")
        _price = State(initialValue: receipt.totalAmount.map { "\($0)" } ?? "")
        _memo = State(initialValue: receipt.memo ?? "")
        _physicalReceipt = State(initialValue: receipt.requiresPhysicalReceipt)
        _existingFileIds = State(initialValue: receipt.receiptFileIds ?? [])

        if let dateStr = receipt.paymentDate {
            let parts = dateStr.split(separator: "-").map(String.init)
            _purchaseDate = State(initialValue: parts.count == 3 ? parts.joined(separator: ".") : "")
        } else {
            _purchaseDate = State(initialValue: "")
        }

        if let months = receipt.periodMonths {
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

    /// 서버 subCategory 원문을 대분류의 지정 소분류 목록 중 하나로 정규화 매칭 (없으면 nil).
    private static func matchSubcategory(_ raw: String?, in category: DeviceCategory) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let key = DeviceCategory.normalizeCategory(raw)
        return category.orderedSubcategories.first { DeviceCategory.normalizeCategory($0) == key }
    }

    // MARK: - Computed

    private var totalFileCount: Int { existingFileIds.count + newImages.count }
    private var canAddMore: Bool { totalFileCount < Self.maxPhotos }
    private var remainingSlots: Int { max(0, Self.maxPhotos - totalFileCount) }
    /// 첨부 이미지는 수정 후에도 최소 1장 이상 유지해야 한다 (서버 스펙).
    private var canRemoveImages: Bool { totalFileCount > Self.minPhotos }

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

    private var warrantySummaryText: String? {
        switch selectedWarranty {
        case 0: return String(localized: "manual.warranty_6m")
        case 1: return String(localized: "manual.warranty_1y")
        case 2: return String(localized: "manual.warranty_2y")
        case 3: return String(localized: "manual.warranty_3y")
        case 4:
            guard let n = Int(customMonthsText), n > 0 else { return nil }
            return customIsYears ? "\(n)년" : "\(n)개월"
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

    private var needsWarrantyHint: Bool {
        if selectedWarranty == nil { return true }
        if selectedWarranty == 4 { return (Int(customMonthsText) ?? 0) <= 0 }
        return false
    }

    private var productNameTooLong: Bool { productName.count > Self.productNameLimit }
    private var memoTooLong: Bool { memo.count > Self.memoLimit }
    private var brandTooLong: Bool { brand.count > Self.brandLimit }
    private var serialTooLong: Bool { serial.count > Self.serialLimit }

    private var canSubmit: Bool {
        !productName.trimmingCharacters(in: .whitespaces).isEmpty
            && !productNameTooLong
            && !purchaseDate.isEmpty
            && totalWarrantyMonths != nil
            && !memoTooLong && !brandTooLong && !serialTooLong
            && totalFileCount >= Self.minPhotos
            && !isSubmitting
    }

    private var priceDisplayBinding: Binding<String> {
        Binding(
            get: { Int(price)?.formattedWithComma ?? "" },
            set: { price = $0.filter(\.isNumber) }
        )
    }

    /// "yyyy.MM.dd" → "yyyy-MM-dd" (서버 전송 포맷)
    private var apiPaymentDate: String? {
        guard !purchaseDate.isEmpty else { return nil }
        return purchaseDate.replacingOccurrences(of: ".", with: "-")
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing20) {
                        categoryCard
                        productCard
                        physicalCard
                        warrantyInfoCard
                        imageSection
                        submitButton
                        Spacer().frame(height: .spacing8)
                    }
                    .padding(.horizontal, .spacing20)
                    .padding(.top, .spacing8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray50)

            if isSubmitting {
                HomeLoadingView(message: "receipt.edit.loading")
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.2), value: isSubmitting)
        // 원본 영수증 추가하기 → 네이티브 액션시트 (카메라로 촬영하기 / 갤러리에서 불러오기 / 닫기)
        .confirmationDialog("", isPresented: $showAddMenu, titleVisibility: .hidden) {
            Button("receipt.register.camera") { openCamera() }
            Button("receipt.register.gallery") { showGalleryPicker = true }
            Button("detail.menu_close", role: .cancel) {}
        }
        .onChange(of: galleryItems) { _, items in loadGalleryImages(items) }
        .photosPicker(
            isPresented: $showGalleryPicker,
            selection: $galleryItems,
            maxSelectionCount: max(1, remainingSlots),
            matching: .images
        )
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in newImages.append(image) }
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showDatePicker) {
            PurchaseDatePickerSheet(
                onConfirm: { purchaseDate = $0; showDatePicker = false },
                onCancel:  { showDatePicker = false }
            )
            .presentationDetents([.medium])
        }
        .alert("카메라를 사용할 수 없습니다.", isPresented: $cameraUnavailable) {
            Button("common.confirm", role: .cancel) {}
        }
        .alert("permission.camera.denied_title", isPresented: $showCameraDenied) {
            Button("permission.open_settings") { permissions.openSettings() }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("permission.camera.denied_message")
        }
        .boatToastHost(toast)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            Text("manual.edit_title")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)
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
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
        .background(Color.colorWhite)
    }

    // MARK: - 카테고리 카드

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            Text("manual.category")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)

            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { categoryExpanded.toggle() }
                } label: {
                    HStack {
                        Text(selectedCategory.pickerLabel)
                            .font(.pretendard(.medium, size: 15))
                            .foregroundStyle(Color.gray900)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.gray500)
                            .rotationEffect(.degrees(categoryExpanded ? 180 : 0))
                    }
                    .padding(.horizontal, .spacing16)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if categoryExpanded {
                    Divider().foregroundStyle(Color.gray200)
                    ForEach(DeviceCategory.allCases, id: \.self) { category in
                        categoryOption(category)
                    }
                }
            }
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(categoryExpanded ? Color.brandPrimary : Color.gray300, lineWidth: 1)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing12) {
                    ForEach(selectedCategory.orderedSubcategories, id: \.self) { name in
                        subcategoryChip(name)
                    }
                }
            }
        }
        .padding(.spacing16)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    private func categoryOption(_ category: DeviceCategory) -> some View {
        let selected = category == selectedCategory
        return Button {
            selectedCategory = category
            selectedSubcategory = nil
            withAnimation(.easeInOut(duration: 0.18)) { categoryExpanded = false }
        } label: {
            Text(category.pickerLabel)
                .font(.pretendard(selected ? .semibold : .regular, size: 15))
                .foregroundStyle(selected ? Color.brandPrimary : Color.gray900)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .spacing16)
                .frame(height: 48)
                .background(selected ? Color.brandSenary : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func subcategoryChip(_ name: String) -> some View {
        let selected = selectedSubcategory == name
        return Button {
            selectedSubcategory = selected ? nil : name
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: .roundedXl)
                    .fill(selected ? Color.brandQuinary : Color.gray100)
                    .frame(width: 64, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: .roundedXl)
                            .stroke(selected ? Color.brandPrimary : Color.clear, lineWidth: 1.5)
                    )
                    .overlay {
                        Image(DeviceImage.assetName(category: selectedCategory.rawValue, subCategory: name))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                Text(name)
                    .font(.pretendard(.regular, size: 11))
                    .foregroundStyle(selected ? Color.brandPrimary : Color.gray600)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 제품 정보 (제품명/구매일/무상 AS 만료기간/메모)

    private var productCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            BoatInputField(
                text: $productName,
                label: "manual.product_name",
                required: true,
                placeholder: "manual.product_name_hint",
                isError: productNameTooLong,
                errorText: LocalizedStringKey("manual.max_length_error \(Self.productNameLimit)")
            )

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
                            if index != 4 {
                                customMonthsText = ""
                                customIsYears = false
                            }
                        }
                    }
                }
            }

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
            } else if let warrantySummaryText {
                Spacer().frame(height: .spacing8)
                Text(warrantySummaryText)
                    .font(.pretendard(.regular, size: 15))
                    .foregroundStyle(Color.gray900)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, .spacing16)
                    .frame(height: 52)
                    .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
                    .overlay(
                        RoundedRectangle(cornerRadius: .roundedLg)
                            .stroke(Color.gray300, lineWidth: 1)
                    )
            }

            if let expiresOn = expiresOnDisplay {
                Spacer().frame(height: .spacing8)
                infoBox(text: "무상 AS 만료일 \(expiresOn)")
            } else if needsWarrantyHint {
                Spacer().frame(height: .spacing8)
                infoBox(textKey: "manual.warranty_hint")
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
                TextEditor(text: $memo)
                    .font(.pretendard(.regular, size: 15))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(height: 120)
            }
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(memoTooLong ? Color.systemError : Color.gray300, lineWidth: 1)
            )
            if memoTooLong {
                Text("manual.max_length_error \(Self.memoLimit)")
                    .font(.pretendard(.medium, size: 13))
                    .foregroundStyle(Color.systemError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("manual.memo_counter")
                    .font(.pretendard(.regular, size: 12))
                    .foregroundStyle(Color.gray400)
            }
        }
    }

    // MARK: - 실물 영수증 보관 여부

    private var physicalCard: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            HStack(spacing: 6) {
                Text("manual.physical_section")
                    .font(.pretendard(.bold, size: 18))
                    .foregroundStyle(Color.gray900)
                InfoTooltip(message: "manual.physical_help")
            }
            radioRow("manual.physical_yes", selected: physicalReceipt == true) { physicalReceipt = true }
            radioRow("detail.physical_no", selected: physicalReceipt == false) { physicalReceipt = false }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing16)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    private func radioRow(_ label: LocalizedStringKey, selected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: .spacing12) {
                ZStack {
                    Circle()
                        .stroke(selected ? Color.brandPrimary : Color.gray300, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle().fill(Color.brandPrimary).frame(width: 12, height: 12)
                    }
                }
                Text(label)
                    .font(.pretendard(.regular, size: 15))
                    .foregroundStyle(selected ? Color.gray900 : Color.gray600)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 보증 정보

    private var warrantyInfoCard: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            Text("manual.warranty_section")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)

            BoatInputField(
                text: $brand,
                label: "manual.brand",
                placeholder: "manual.brand_hint",
                isError: brandTooLong,
                errorText: LocalizedStringKey("manual.max_length_error \(Self.brandLimit)")
            )
            BoatInputField(
                text: priceDisplayBinding,
                label: "manual.price",
                placeholder: "manual.price_hint",
                keyboard: .numberPad
            )
            serialField
        }
        .padding(.spacing16)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    private var serialField: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text("manual.serial")
                    .font(.pretendard(.medium, size: 14))
                    .foregroundStyle(Color.gray600)
                InfoTooltip(message: "manual.serial_help")
            }
            Spacer().frame(height: .spacing8)
            TextField("", text: $serial, prompt: Text("manual.serial_hint").foregroundStyle(Color.gray400))
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.gray900)
                .padding(.horizontal, .spacing16)
                .frame(height: 52)
                .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
                .overlay(
                    RoundedRectangle(cornerRadius: .roundedLg)
                        .stroke(serialTooLong ? Color.systemError : Color.gray300, lineWidth: 1)
                )
            if serialTooLong {
                Spacer().frame(height: 6)
                Text("manual.max_length_error \(Self.serialLimit)")
                    .font(.pretendard(.medium, size: 13))
                    .foregroundStyle(Color.systemError)
            }
        }
    }

    // MARK: - 원본 영수증

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            Text("detail.original_receipt")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing12) {
                    if canAddMore {
                        addTile
                    }
                    ForEach(Array(existingFileIds.enumerated()), id: \.offset) { index, _ in
                        existingFilePlaceholder(index: index)
                    }
                    ForEach(Array(newImages.enumerated()), id: \.offset) { index, image in
                        imageThumbnail(image, index: index)
                    }
                }
            }

            if totalFileCount < Self.minPhotos {
                Text("manual.min_image_hint")
                    .font(.pretendard(.medium, size: 13))
                    .foregroundStyle(Color.systemError)
            }
        }
        .padding(.spacing16)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    private var addTile: some View {
        Button {
            showAddMenu = true
        } label: {
            VStack(spacing: .spacing8) {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
                Text("manual.add_image")
                    .font(.pretendard(.medium, size: 13))
                    .foregroundStyle(Color.brandPrimary)
            }
            .frame(width: 100, height: 100)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(Color.brandTertiary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // TODO: 파일 서빙 URL 계약 확정 시 실제 이미지 로드로 교체. 기존 첨부는 개별 삭제 API가 없어
    // X는 로컬 편집 목록에서만 제거한다(수정 완료 API 연동 시 최종 반영 방식 결정 필요).
    private func existingFilePlaceholder(index: Int) -> some View {
        RoundedRectangle(cornerRadius: .roundedLg)
            .fill(Color.gray100)
            .frame(width: 100, height: 100)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.gray400)
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    removeExistingFile(at: index)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.colorWhite)
                        .frame(width: 24, height: 24)
                        .background(Color.gray900.opacity(0.5), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
    }

    private func imageThumbnail(_ image: UIImage, index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
            .overlay(alignment: .topTrailing) {
                Button {
                    guard canRemoveImages else { return }
                    newImages.remove(at: index)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.colorWhite)
                        .frame(width: 24, height: 24)
                        .background(Color.gray900.opacity(0.5), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
    }

    // MARK: - 수정 완료 버튼

    private var submitButton: some View {
        let enabled = canSubmit
        return Button {
            submit()
        } label: {
            Text("manual.edit_submit")
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
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func infoBox(text: String? = nil, textKey: LocalizedStringKey? = nil) -> some View {
        HStack(spacing: .spacing8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.brandPrimary)
            Group {
                if let text { Text(text) } else if let textKey { Text(textKey) }
            }
            .font(.pretendard(.semibold, size: 13))
            .foregroundStyle(Color.brandPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .spacing12)
        .padding(.vertical, 10)
        .background(Color.brandSenary, in: RoundedRectangle(cornerRadius: .roundedLg))
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

    private func openCamera() {
        guard canAddMore else { return }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraUnavailable = true
            return
        }
        Task {
            switch permissions.cameraStatus {
            case .granted:
                showCamera = true
            case .notDetermined:
                let status = await permissions.requestCameraPermission()
                if status == .granted { showCamera = true }
                else if status == .denied { showCameraDenied = true }
            case .denied:
                showCameraDenied = true
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
                newImages.append(contentsOf: loaded.prefix(remainingSlots))
                galleryItems = []
            }
        }
    }

    private func removeExistingFile(at index: Int) {
        guard canRemoveImages else { return }
        existingFileIds.remove(at: index)
    }

    /// 영수증 수정: 신규 이미지 업로드 → 유지할 기존 fileId와 합쳐 PATCH → 상세로 복귀.
    private func submit() {
        guard canSubmit, !isSubmitting else { return }

        let sub = (selectedSubcategory == "기타" ? nil : selectedSubcategory)
        let fields = ReceiptUpdateFields(
            itemName: productName.trimmingCharacters(in: .whitespaces),
            brandName: brand.trimmingCharacters(in: .whitespaces),
            serialNumber: serial.trimmingCharacters(in: .whitespaces),
            paymentDate: apiPaymentDate,
            totalAmount: Int(price),
            periodMonths: totalWarrantyMonths,
            category: selectedCategory.rawValue,
            subCategory: sub,
            memo: memo.trimmingCharacters(in: .whitespaces),
            requiresPhysicalReceipt: physicalReceipt ?? false
        )
        let imagesToUpload = newImages
        let remaining = existingFileIds

        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                _ = try await ReceiptRepository.shared.updateReceipt(
                    id: receiptId,
                    newImages: imagesToUpload,
                    remainingFileIds: remaining,
                    fields: fields
                )
                onUpdated()
            } catch {
                toast.showError(String(localized: "receipt.edit.fail"))
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
