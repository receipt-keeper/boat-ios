//
//  ReceiptEditView.swift
//  BOAT
//
//  영수증 상세 화면의 케밥 → "수정하기"로 진입하는 수정 화면. 디자인 확정본 반영.
//  - 카테고리: 대분류 드롭다운 + 소분류 칩 (ReceiptManualInputView와 동일 패턴)
//  - 제품명/구매일/무상 AS 만료기간/메모: 글자 수 제한 초과 시 에러 테두리+안내문 (자르지 않음)
//  - 실물 영수증 보관 여부: 라디오 / 보증 정보: 브랜드·가격·시리얼(도움말 아이콘)
//  - 원본 영수증: 추가하기 탭 시 PhotoSourceSheet(카메라로 촬영하기/갤러리에서 불러오기/닫기),
//    썸네일 탭 시 ImageViewerScreen(기존 첨부는 contentPath로 실제 이미지 로드)
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

    // 실물 영수증 보관 여부 (체크박스)
    @State private var physicalReceipt = false

    // 보증 정보
    @State private var brand: String
    @State private var price: String
    @State private var serial: String

    // 원본 영수증 — 기존 첨부(contentPath로 실제 이미지 로드) + 신규 추가(UIImage)
    @State private var existingFiles: [ReceiptFile]
    @State private var newImages: [UIImage] = []
    @State private var galleryItems: [PhotosPickerItem] = []
    @State private var showAddMenu = false
    @State private var showCamera = false
    @State private var showGalleryPicker = false
    @State private var cameraUnavailable = false
    @State private var showCameraDenied = false
    // 썸네일 탭 → 전체화면 이미지 뷰어
    @State private var showViewer = false
    @State private var viewerIndex = 0

    @State private var isSubmitting = false
    @State private var toast = BoatToastState()
    // 뒤로가기 시 작성 중인 내용 이탈 확인
    @State private var showExitConfirm = false

    // 원본 스냅샷 — 뒤로가기 시 실제로 변경된 내용이 있는지 비교하기 위함 (변경 없으면 확인 팝업 생략)
    private let originalCategory: DeviceCategory
    private let originalSubcategory: String?
    private let originalProductName: String
    private let originalPurchaseDate: String
    private let originalWarranty: Int?
    private let originalCustomMonthsText: String
    private let originalMemo: String
    private let originalPhysicalReceipt: Bool
    private let originalBrand: String
    private let originalPrice: String
    private let originalSerial: String
    private let originalFileIds: [String]

    init(receipt: Receipt, onBack: @escaping () -> Void, onUpdated: @escaping () -> Void = {}) {
        self.receiptId = receipt.receiptId
        self.onBack = onBack
        self.onUpdated = onUpdated

        let category = DeviceCategory.from(serverValue: receipt.category) ?? .kitchen
        let subcategory = Self.matchSubcategory(receipt.subCategory, in: category)
        _selectedCategory = State(initialValue: category)
        _selectedSubcategory = State(initialValue: subcategory)
        originalCategory = category
        originalSubcategory = subcategory

        let name = receipt.itemName
        let brandValue = receipt.brandName ?? ""
        let serialValue = receipt.serialNumber ?? ""
        let priceValue = receipt.totalAmount.map { "\($0)" } ?? ""
        let memoValue = receipt.memo ?? ""
        let existingFilesValue = receipt.receiptFiles ?? []
        _productName = State(initialValue: name)
        _brand = State(initialValue: brandValue)
        _serial = State(initialValue: serialValue)
        _price = State(initialValue: priceValue)
        _memo = State(initialValue: memoValue)
        _physicalReceipt = State(initialValue: receipt.requiresPhysicalReceipt ?? false)
        _existingFiles = State(initialValue: existingFilesValue)
        originalProductName = name
        originalBrand = brandValue
        originalSerial = serialValue
        originalPrice = priceValue
        originalMemo = memoValue
        originalPhysicalReceipt = receipt.requiresPhysicalReceipt ?? false
        originalFileIds = existingFilesValue.map(\.fileId)

        let dateValue: String
        if let dateStr = receipt.paymentDate {
            let parts = dateStr.split(separator: "-").map(String.init)
            dateValue = parts.count == 3 ? parts.joined(separator: ".") : ""
        } else {
            dateValue = ""
        }
        _purchaseDate = State(initialValue: dateValue)
        originalPurchaseDate = dateValue

        var warrantyValue: Int?
        var customMonthsValue = ""
        if let months = receipt.periodMonths {
            switch months {
            case 6:  warrantyValue = 0
            case 12: warrantyValue = 1
            case 24: warrantyValue = 2
            case 36: warrantyValue = 3
            default:
                warrantyValue = 4
                customMonthsValue = "\(months)"
            }
        }
        _selectedWarranty = State(initialValue: warrantyValue)
        _customMonthsText = State(initialValue: customMonthsValue)
        originalWarranty = warrantyValue
        originalCustomMonthsText = customMonthsValue
    }

    /// 서버 subCategory 원문을 대분류의 지정 소분류 목록 중 하나로 정규화 매칭 (없으면 nil).
    private static func matchSubcategory(_ raw: String?, in category: DeviceCategory) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let key = DeviceCategory.normalizeCategory(raw)
        return category.orderedSubcategories.first { DeviceCategory.normalizeCategory($0) == key }
    }

    // MARK: - Computed

    private var totalFileCount: Int { existingFiles.count + newImages.count }
    private var canAddMore: Bool { totalFileCount < Self.maxPhotos }

    /// 소분류 칩 노출 순서 — 진입 시점의 기존 소분류만 맨 앞에 고정(1회성). 이후 사용자가
    /// 다른 소분류를 직접 선택해도 배열 순서 자체는 바뀌지 않는다(선택 표시만 이동).
    private var displayedSubcategories: [String] {
        let base = selectedCategory.orderedSubcategories
        guard let original = originalSubcategory, let index = base.firstIndex(of: original) else { return base }
        var reordered = base
        reordered.remove(at: index)
        reordered.insert(original, at: 0)
        return reordered
    }
    private var remainingSlots: Int { max(0, Self.maxPhotos - totalFileCount) }
    /// 이미지 뷰어용 전체 목록 — 화면에 보이는 순서(최근 추가한 신규 첨부 → 기존 첨부)와 동일해야 인덱스가 맞는다.
    private var viewerItems: [ImageViewerItem] {
        newImages.reversed().map { .local($0) } + existingFiles.map { .remote($0) }
    }

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

    private var productNameTooLong: Bool { productName.count >= ReceiptTextLimits.productName }
    private var memoTooLong: Bool { memo.count >= ReceiptTextLimits.memo }
    private var brandTooLong: Bool { brand.count >= ReceiptTextLimits.brand }
    private var serialTooLong: Bool { serial.count >= ReceiptTextLimits.serial }
    private var priceLimitReached: Bool { price.count >= 9 }

    private var canSubmit: Bool {
        !productName.trimmingCharacters(in: .whitespaces).isEmpty
            && !purchaseDate.isEmpty
            && totalWarrantyMonths != nil
            && totalFileCount >= Self.minPhotos
            && hasChanges
            && !isSubmitting
    }

    /// 숫자만 입력, 최대 9자리(999,999,999), 입력 중 천 단위 콤마 자동 표시.
    private var priceDisplayBinding: Binding<String> {
        Binding(
            get: { Int(price)?.formattedWithComma ?? "" },
            set: { price = String($0.filter(\.isNumber).prefix(9)) }
        )
    }

    /// "yyyy.MM.dd" → "yyyy-MM-dd" (서버 전송 포맷)
    private var apiPaymentDate: String? {
        guard !purchaseDate.isEmpty else { return nil }
        return purchaseDate.replacingOccurrences(of: ".", with: "-")
    }

    /// "yyyy.MM.dd" → "yyyy-MM-dd" (서버 전송 포맷)
    private var apiExpiresOn: String? {
        expiresOnDisplay?.replacingOccurrences(of: ".", with: "-")
    }

    /// 원본 대비 실제로 변경된 내용이 있는지 — 없으면 뒤로가기 시 이탈 확인 팝업을 생략한다.
    private var hasChanges: Bool {
        selectedCategory != originalCategory
            || selectedSubcategory != originalSubcategory
            || productName != originalProductName
            || purchaseDate != originalPurchaseDate
            || selectedWarranty != originalWarranty
            || customMonthsText != originalCustomMonthsText
            || customIsYears
            || memo != originalMemo
            || physicalReceipt != originalPhysicalReceipt
            || brand != originalBrand
            || price != originalPrice
            || serial != originalSerial
            || !newImages.isEmpty
            || existingFiles.map(\.fileId) != originalFileIds
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
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    // 입력창 외부(빈 영역) 탭 시 키보드 닫기. ScrollView를 감싸는 상위 뷰가 아니라
                    // 스크롤되는 콘텐츠 쪽에 달아야 한다 — ScrollView 자체 제스처에 가려 상위
                    // onTapGesture가 거의 인식되지 않는 문제가 있었다.
                    .onTapGesture { endEditing() }
                }
                .scrollDismissesKeyboard(.interactively)
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
        .animation(.easeInOut(duration: 0.2), value: showAddMenu)
        // 원본 영수증 추가하기 → 화면 하단 전체 폭 액션 시트 (카메라로 촬영하기 / 갤러리에서 불러오기 / 닫기)
        .overlay {
            if showAddMenu {
                PhotoSourceSheet(
                    onCamera: { showAddMenu = false; openCamera() },
                    onGallery: { showAddMenu = false; showGalleryPicker = true },
                    onDismiss: { showAddMenu = false }
                )
            }
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
        // 썸네일 탭 → 전체화면 이미지 뷰어 (기존 첨부 + 신규 첨부 순서 그대로)
        .fullScreenCover(isPresented: $showViewer) {
            ImageViewerScreen(
                items: viewerItems,
                initialIndex: viewerIndex,
                onClose: { showViewer = false }
            )
        }
        .sheet(isPresented: $showDatePicker) {
            PurchaseDatePickerSheet(
                onSelect: { purchaseDate = $0; showDatePicker = false }
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
        .boatDialog(
            isPresented: $showExitConfirm,
            title: "dialog.exit_draft.title",
            message: "dialog.exit_draft.message",
            confirmText: "dialog.exit_draft.confirm",
            cancelText: "common.cancel",
            onConfirm: onBack
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            Text("manual.edit_title")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)
            HStack {
                Button {
                    if hasChanges { showExitConfirm = true } else { onBack() }
                } label: {
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
                .font(.pretendard(.bold, size: 16))
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

            // 소분류 칩 — 진입 시점의 기존 소분류만 맨 앞에 고정, 이후 선택 변경엔 순서 유지.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing12) {
                    ForEach(displayedSubcategories, id: \.self) { name in
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
                        // stroke()는 경계선을 중심으로 안팎에 절반씩 그려 프레임 밖으로 살짝
                        // 삐져나오는데, 가로 스크롤 안에 있는 칩이라 그 삐져나온 바깥쪽 절반이
                        // 스크롤뷰 레이아웃 경계에 잘려 위쪽 변 테두리가 흐릿하게 보였다.
                        // strokeBorder()는 프레임 안쪽으로만 그려 잘릴 여지가 없다.
                        RoundedRectangle(cornerRadius: .roundedXl)
                            .strokeBorder(selected ? Color.brandPrimary : Color.clear, lineWidth: 1.5)
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
                errorText: LocalizedStringKey("manual.max_length_error \(ReceiptTextLimits.productName)"),
                maxLength: ReceiptTextLimits.productName
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
                        // 매 keystroke마다 새 Binding(get:set:)을 만들면 IME 조합 중인 글자가
                        // 분리/중복될 수 있어, 평범한 바인딩 + onChange 보정으로 대체한다.
                        .onChange(of: customMonthsText) { _, newValue in
                            let filtered = String(newValue.filter(\.isNumber).prefix(ReceiptTextLimits.warrantyMonths))
                            if filtered != newValue { customMonthsText = filtered }
                        }
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
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if memo.isEmpty {
                    Text("manual.memo_hint")
                        .font(.pretendard(.regular, size: 15))
                        .foregroundStyle(Color.gray400)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                }
                BoatTextEditor(
                    text: $memo,
                    placeholder: "manual.memo_hint",
                    maxLength: ReceiptTextLimits.memo,
                    height: 120
                )
            }
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(memoTooLong ? Color.systemError : Color.gray300, lineWidth: 1)
            )
            // 디자인 가이드: "최대 100자" 안내문구는 박스 밖이 아니라 박스 안 우측 하단에 표시.
            .overlay(alignment: .bottomTrailing) {
                Text("manual.memo_counter")
                    .font(.pretendard(.regular, size: 12))
                    .foregroundStyle(Color.gray400)
                    .padding(.trailing, 12)
                    .padding(.bottom, 10)
            }
            if memoTooLong {
                Text("manual.max_length_error \(ReceiptTextLimits.memo)")
                    .font(.pretendard(.medium, size: 13))
                    .foregroundStyle(Color.systemError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 실물 영수증 보관 여부 (체크박스)

    private var physicalCard: some View {
            // 💡 1. 제목(Title)과 설명(Description) 사이의 호흡을 확보합니다. (기존 .spacing8 -> 14)
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: .spacing12) {
                    Text("manual.physical_section")
                        .font(.pretendard(.bold, size: 16))
                        .foregroundStyle(Color.gray900)
                    Spacer()
                    physicalCheckbox
                }
                
                Text("manual.physical_help")
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray600)
                    .lineSpacing(4) // 💡 2. 텍스트 줄간격을 살짝 넓혀 가독성을 높입니다.
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20) // 💡 3. 카드 내부의 넉넉한 여백 텐션 반영 (기존 .spacing16 -> 20)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
            .overlay(
                // 💡 4. 경계선이 잘리거나 흐릿해지지 않도록 strokeBorder 사용
                RoundedRectangle(cornerRadius: .rounded2xl)
                    .strokeBorder(Color.gray200, lineWidth: 1)
            )
        }

        private var physicalCheckbox: some View {
            Button { physicalReceipt.toggle() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: .roundedSm)
                        .fill(physicalReceipt ? Color.brandPrimary : Color.colorWhite)
                    
                    // 💡 체크박스 테두리 역시 strokeBorder로 깔끔하게 처리 (lineWidth 1.5 -> 1 로 변경하여 스크린샷처럼 얇고 세련되게)
                    RoundedRectangle(cornerRadius: .roundedSm)
                        .strokeBorder(physicalReceipt ? Color.brandPrimary : Color.gray300, lineWidth: 1)
                    
                    if physicalReceipt {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold)) // 스크린샷의 굵고 선명한 체크마크
                            .foregroundStyle(Color.colorWhite)
                    }
                }
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }

    // MARK: - 보증 정보

    private var warrantyInfoCard: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            // 디자인 가이드: 섹션 타이틀은 흰 박스 밖(페이지 배경)에 위치.
            Text("manual.warranty_section")
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(Color.gray900)

            VStack(alignment: .leading, spacing: .spacing16) {
                BoatInputField(
                    text: $brand,
                    label: "manual.brand",
                    placeholder: "manual.brand_hint",
                    isError: brandTooLong,
                    errorText: LocalizedStringKey("manual.max_length_error \(ReceiptTextLimits.brand)"),
                    maxLength: ReceiptTextLimits.brand
                )
                BoatInputField(
                    text: priceDisplayBinding,
                    label: "manual.price",
                    placeholder: "manual.price_hint",
                    isError: priceLimitReached,
                    errorText: "최대 999,999,999원까지 입력 가능합니다.",
                    keyboard: .numberPad
                )
                serialField
            }
            .padding(.spacing16)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
        }
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
            TextField(
                "",
                text: $serial,
                prompt: Text("manual.serial_hint").foregroundStyle(Color.gray400)
            )
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.gray900)
                .padding(.horizontal, .spacing16)
                .frame(height: 52)
                .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
                .overlay(
                    RoundedRectangle(cornerRadius: .roundedLg)
                        .stroke(serialTooLong ? Color.systemError : Color.gray300, lineWidth: 1)
                )
                // 매 keystroke마다 새 Binding(get:set:)을 만들면 IME 조합 중인 글자가
                // 분리/중복될 수 있어, 평범한 바인딩 + onChange 보정으로 대체한다.
                .onChange(of: serial) { _, newValue in
                    if newValue.count > ReceiptTextLimits.serial {
                        serial = String(newValue.prefix(ReceiptTextLimits.serial))
                    }
                }
            if serialTooLong {
                Spacer().frame(height: 6)
                Text("manual.max_length_error \(ReceiptTextLimits.serial)")
                    .font(.pretendard(.medium, size: 13))
                    .foregroundStyle(Color.systemError)
            }
        }
    }

    // MARK: - 원본 영수증

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            HStack(spacing: 0) {
                Text("detail.original_receipt")
                    .font(.pretendard(.bold, size: 16))
                    .foregroundStyle(Color.gray900)
                Text(" *")
                    .font(.pretendard(.bold, size: 16))
                    .foregroundStyle(Color.systemError)
            }
            Text("detail.original_receipt_hint")
                .font(.pretendard(.regular, size: 12))
                .foregroundStyle(Color.gray500)

            // "+" 추가 버튼은 항상 맨 왼쪽 고정. 그다음은 가장 최근에 추가한 신규 이미지부터,
            // 마지막으로 기존 첨부 순서로 배치한다.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing12) {
                    if canAddMore {
                        addTile
                    }
                    ForEach(Array(newImages.enumerated().reversed()), id: \.offset) { index, image in
                        imageThumbnail(image, index: index, viewerIndex: newImages.count - 1 - index)
                    }
                    ForEach(Array(existingFiles.enumerated()), id: \.element.fileId) { index, file in
                        existingFileThumbnail(file, index: index)
                    }
                }
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
            // stroke()는 프레임 밖으로 절반 삐져나오는데, 가로 스크롤 안에서는 그 바깥쪽
            // 절반이 잘려 테두리가 흐릿해 보인다. strokeBorder()는 안쪽으로만 그려 잘리지 않는다.
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .strokeBorder(Color.brandTertiary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // 기존 첨부 — contentPath로 실제 이미지를 로드(AuthenticatedImage). X는 개별 삭제 API가 없어
    // 로컬 편집 목록에서만 제거한다(수정 완료 시 최종 remainingFileIds에 반영).
    private func existingFileThumbnail(_ file: ReceiptFile, index: Int) -> some View {
        RoundedRectangle(cornerRadius: .roundedLg)
            .fill(Color.gray100)
            .frame(width: 100, height: 100)
            .overlay { AuthenticatedImage(contentPath: file.contentPath) }
            .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
            .contentShape(RoundedRectangle(cornerRadius: .roundedLg))
            .onTapGesture {
                viewerIndex = newImages.count + index
                showViewer = true
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
                        // 시각적 크기는 그대로 두고 탭 영역만 사방 2pt씩 넓힌다.
                        .padding(-2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
    }

    private func imageThumbnail(_ image: UIImage, index: Int, viewerIndex viewerIdx: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
            .contentShape(RoundedRectangle(cornerRadius: .roundedLg))
            .onTapGesture {
                viewerIndex = viewerIdx
                showViewer = true
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    newImages.remove(at: index)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.colorWhite)
                        .frame(width: 24, height: 24)
                        .background(Color.gray900.opacity(0.5), in: Circle())
                        // 시각적 크기는 그대로 두고 탭 영역만 사방 2pt씩 넓힌다.
                        .padding(-2)
                        .contentShape(Rectangle())
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
        // 이미지 미첨부 시 탭해서 경고 토스트를 띄워야 하므로 여기서 막지 않고 submit() 안에서 처리한다.
        .disabled(isSubmitting)
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
                    // 💡 1. 폰트 사이즈는 디자인 가이드대로 12를 그대로 유지합니다.
                    .font(.pretendard(selected ? .semibold : .medium, size: 12))
                    .foregroundStyle(selected ? Color.colorWhite : Color.gray700)
                    // 💡 2. 기존의 좁은 여백(8) 대신, 좌우 16의 넉넉한 여백을 주어 글자에 맞춰 자연스럽게 늘어나도록 합니다.
                    .padding(.horizontal, 16)
                    // 💡 3. 복잡한 min/max 조건을 지우고 가이드 스펙인 '높이 28'을 강제 고정합니다.
                    .frame(height: 28)
                    .background(selected ? Color.brandPrimary : Color.clear, in: Capsule())
                    .overlay(
                        // (이전에 수정했던 strokeBorder는 안전하게 잘 유지되어 있습니다!)
                        Capsule().strokeBorder(selected ? Color.clear : Color.gray300, lineWidth: 1)
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

    /// 입력창 외부 탭 시 현재 포커스된 필드의 키보드를 닫는다.
    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

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
        existingFiles.remove(at: index)
    }

    /// 영수증 수정: 신규 이미지 업로드 → 유지할 기존 fileId와 합쳐 PATCH → 상세로 복귀.
    private func submit() {
        guard !isSubmitting else { return }
        // 비활성 버튼 탭 시 화면 최상단부터 순서대로 누락 항목을 확인해 안내한다.
        guard !productName.trimmingCharacters(in: .whitespaces).isEmpty else {
            toast.showError(String(localized: "manual.product_name_required"))
            return
        }
        guard !purchaseDate.isEmpty else {
            toast.showError(String(localized: "manual.purchase_date_required"))
            return
        }
        guard totalWarrantyMonths != nil else {
            toast.showError(String(localized: "manual.warranty_required"))
            return
        }
        guard totalFileCount >= Self.minPhotos else {
            toast.showError(String(localized: "manual.image_required"))
            return
        }
        guard hasChanges else {
            toast.showError(String(localized: "receipt.edit.no_changes"))
            return
        }
        guard canSubmit else { return }

        let sub = (selectedSubcategory == "기타" ? nil : selectedSubcategory)
        let fields = ReceiptUpdateFields(
            itemName: productName.trimmingCharacters(in: .whitespaces),
            brandName: brand.trimmingCharacters(in: .whitespaces),
            serialNumber: serial.trimmingCharacters(in: .whitespaces),
            paymentDate: apiPaymentDate,
            totalAmount: Int(price),
            periodMonths: totalWarrantyMonths,
            expiresOn: apiExpiresOn,
            category: selectedCategory.rawValue,
            subCategory: sub,
            memo: memo.trimmingCharacters(in: .whitespaces),
            requiresPhysicalReceipt: physicalReceipt
        )
        let imagesToUpload = newImages
        let remaining = existingFiles.map(\.fileId)

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
