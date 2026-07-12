//
//  ReceiptManualInputView.swift
//  BOAT
//
//  영수증 직접 입력 화면. OCR 성공 시 분석 결과 프리필, 직접 입력 시 빈 폼으로 진입.
//  Android ReceiptManualInputScreen 대응. 디자인 확정본 반영:
//  - 등록된 이미지 확인: 추가하기 타일(PhotoSourceSheet) + 썸네일(탭=뷰어, 삭제)
//  - 카테고리: 대분류 드롭다운 + 소분류 칩(지정 순서)
//  - 제품 정보 / 보증 정보: 접이식 섹션
//  - 실물 영수증 보관 여부: 체크박스(필요함, 기본 unchecked)
//  필수(*): 제품명 / 구매일 / 무상 AS 만료기간.
//

import SwiftUI
import PhotosUI

struct ReceiptManualInputView: View {

    let onBack: () -> Void
    /// 영수증 등록 성공 → 홈으로 복귀 처리 (상위에서 등록 플로우 전체를 닫음)
    var onComplete: () -> Void = {}

    @Environment(PermissionManager.self) private var permissions

    /// OCR 분석 성공 후 진입(true) — 타이틀 "영수증 입력" + 추가하기 타일이 맨 뒤로 이동.
    /// 직접 입력 진입(false) — 타이틀 "영수증 직접 입력" + 추가하기 타일이 맨 앞.
    private let isFromOCR: Bool
    /// OCR로 최초 설정된(또는 매칭 실패 시 nil) 소분류 — 진입 시점 값만 소분류 칩 맨 앞
    /// 고정에 쓰고, 이후 사용자가 다른 소분류로 바꿔도 이 값은 안 바뀐다.
    private let originalSubcategory: String?

    private static let maxPhotos = 5
    private static let productNameLimit = 50
    private static let brandLimit = 50
    private static let serialLimit = 50
    private static let warrantyOptions: [LocalizedStringKey] = [
        "manual.warranty_6m", "manual.warranty_1y", "manual.warranty_2y", "manual.warranty_3y", "manual.warranty_custom",
    ]

    @State private var images: [UIImage]
    @State private var galleryItems: [PhotosPickerItem] = []

    // 이미지 추가 메뉴(카메라/갤러리) + 카메라 권한
    @State private var showAddMenu = false
    @State private var showCamera = false
    @State private var showGalleryPicker = false
    @State private var cameraUnavailable = false
    @State private var showCameraDenied = false

    // 카테고리
    @State private var selectedCategory: DeviceCategory
    @State private var selectedSubcategory: String?
    @State private var categoryExpanded = false

    // 제품 정보
    @State private var productName = ""
    @State private var purchaseDate = ""
    @State private var selectedWarranty: Int?
    @State private var customMonthsText = ""
    @State private var customIsYears = false
    @State private var memo = ""
    @State private var showDatePicker = false
    @State private var productExpanded = true

    // 실물 영수증 보관 여부 (체크박스, 기본 unchecked)
    @State private var physicalReceipt = false

    // 보증 정보
    @State private var brand = ""
    @State private var price = ""
    @State private var serial = ""
    @State private var warrantyExpanded = true

    @State private var isSubmitting = false
    @State private var completedReceipt: Receipt?
    @State private var toast = BoatToastState()
    // 뒤로가기 시 작성 중인 내용 이탈 확인 (OCR 결과 기반 진입 시 문구 다름)
    @State private var showExitConfirm = false
    // 썸네일 탭 → 전체화면 이미지 뷰어
    @State private var showViewer = false
    @State private var viewerIndex = 0

    init(images: [UIImage], ocrResult: OcrAnalysis? = nil, onBack: @escaping () -> Void, onComplete: @escaping () -> Void = {}) {
        _images = State(initialValue: images)
        self.onBack = onBack
        self.onComplete = onComplete
        self.isFromOCR = ocrResult != nil

        // 기본 대분류는 주방가전 (디자인 기본값). OCR 카테고리가 있으면 그걸로.
        var category = DeviceCategory.kitchen
        if let cat = ocrResult?.category, let matched = DeviceCategory.from(serverValue: cat) {
            category = matched
        }
        _selectedCategory = State(initialValue: category)

        // OCR이 인식한 소분류 — 매칭되면 소분류 칩 초기 선택 + 맨 앞 고정 기준값으로 쓴다.
        let subcategory = Self.matchSubcategory(ocrResult?.subCategory, in: category)
        _selectedSubcategory = State(initialValue: subcategory)
        self.originalSubcategory = subcategory

        guard let ocr = ocrResult else { return }

        _productName = State(initialValue: String((ocr.itemName ?? "").prefix(Self.productNameLimit)))
        _brand = State(initialValue: String((ocr.brandName ?? "").prefix(Self.brandLimit)))
        _serial = State(initialValue: String((ocr.serialNumber ?? "").prefix(Self.serialLimit)))

        if let dateStr = ocr.paymentDate {
            let parts = dateStr.split(separator: "-").map(String.init)
            if parts.count == 3 {
                _purchaseDate = State(initialValue: parts.joined(separator: "."))
            }
        }
        if let amount = ocr.totalAmount {
            _price = State(initialValue: String("\(amount)".prefix(9)))
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

    /// 서버 subCategory 원문을 대분류의 지정 소분류 목록 중 하나로 정규화 매칭 (없으면 nil).
    /// (ReceiptEditView.matchSubcategory와 동일 로직)
    private static func matchSubcategory(_ raw: String?, in category: DeviceCategory) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let key = DeviceCategory.normalizeCategory(raw)
        return category.orderedSubcategories.first { DeviceCategory.normalizeCategory($0) == key }
    }

    // MARK: - Computed

    private var remainingSlots: Int { max(0, Self.maxPhotos - images.count) }
    private var canAddMore: Bool { images.count < Self.maxPhotos }

    /// 소분류 칩 노출 순서 — OCR로 최초 설정된 소분류만 맨 앞에 고정(1회성). 이후 사용자가
    /// 다른 소분류를 직접 선택해도 배열 순서 자체는 바뀌지 않는다(선택 표시만 이동).
    private var displayedSubcategories: [String] {
        let base = selectedCategory.orderedSubcategories
        guard let original = originalSubcategory, let index = base.firstIndex(of: original) else { return base }
        var reordered = base
        reordered.remove(at: index)
        reordered.insert(original, at: 0)
        return reordered
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

    /// 선택된 보증기간을 읽기전용 박스로 보여줄 텍스트 ("6개월" 등). 직접입력 모드에서는 숨김.
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

    private var canSubmit: Bool {
        !images.isEmpty
            && !productName.trimmingCharacters(in: .whitespaces).isEmpty
            && !purchaseDate.isEmpty
            && totalWarrantyMonths != nil
    }

    /// 숫자만 입력, 최대 9자리(999,999,999), 입력 중 천 단위 콤마 자동 표시.
    private var priceDisplayBinding: Binding<String> {
        Binding(
            get: { Int(price)?.formattedWithComma ?? "" },
            set: { price = String($0.filter(\.isNumber).prefix(9)) }
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing20) {
                        imageSection
                        categoryCard
                        productCard
                        physicalCard
                        warrantyCard
                        submitButton
                        Spacer().frame(height: .spacing8)
                    }
                    .padding(.horizontal, .spacing20)
                    .padding(.top, .spacing8)
                    .padding(.bottom, .spacing16)
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
                HomeLoadingView(message: "receipt.register.loading")
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.2), value: isSubmitting)
        .animation(.easeInOut(duration: 0.2), value: showAddMenu)
        // 추가하기 → 화면 하단 전체 폭 액션 시트 (카메라로 촬영하기 / 갤러리에서 불러오기 / 닫기)
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
            CameraPicker { image in addImages([image]) }
                .ignoresSafeArea()
        }
        // 썸네일 탭 → 전체화면 이미지 뷰어
        .fullScreenCover(isPresented: $showViewer) {
            ImageViewerScreen(
                items: images.map { .local($0) },
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
        // 등록 성공 → 완료 화면 ("홈으로 가기" 탭 시 onComplete로 등록 플로우 전체 닫힘)
        .fullScreenCover(item: $completedReceipt) { receipt in
            ReceiptRegisterCompleteView(receiptId: receipt.receiptId, onGoHome: onComplete)
        }
        .boatDialog(
            isPresented: $showExitConfirm,
            title: isFromOCR ? "dialog.exit_ocr.title" : "dialog.exit_draft.title",
            message: isFromOCR ? "dialog.exit_ocr.message" : "dialog.exit_draft.message",
            confirmText: isFromOCR ? "dialog.exit_ocr.confirm" : "dialog.exit_draft.confirm",
            cancelText: "common.cancel",
            onConfirm: onBack
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            Text(isFromOCR ? "manual.title_ocr" : "manual.title")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)
            HStack {
                Button { showExitConfirm = true } label: {
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
    }

    // MARK: - 등록된 이미지 확인

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            sectionTitle("manual.image_section", required: true)

            // 직접 입력: + 버튼 항상 왼쪽 고정. OCR 분석 결과 확인: + 버튼이 이미지들 뒤로 밀려남.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing12) {
                    if !isFromOCR && canAddMore { addTile }
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        imageThumbnail(image, index: index)
                    }
                    if isFromOCR && canAddMore { addTile }
                }
            }
        }
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

    private func imageThumbnail(_ image: UIImage, index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
            .contentShape(RoundedRectangle(cornerRadius: .roundedLg))
            .onTapGesture {
                viewerIndex = index
                showViewer = true
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    images.remove(at: index)
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

    // MARK: - 카테고리 카드 (대분류 드롭다운 + 소분류 칩)

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            Text("manual.category")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)

            // 대분류 드롭다운
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

            // 소분류 칩 — OCR로 최초 설정된 소분류만 맨 앞에 고정, 이후 선택 변경엔 순서 유지.
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

    // MARK: - 제품 정보 카드 (접이식)

    private var productCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsibleHeader("manual.product_section", expanded: $productExpanded)

            if productExpanded {
                Spacer().frame(height: .spacing16)

                BoatInputField(
                    text: Binding(
                        get: { productName },
                        set: { productName = String($0.prefix(Self.productNameLimit)) }
                    ),
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
                    infoBox(text: "무상 AS 만료일 \(expiresOn)", systemIcon: "info.circle.fill")
                } else if needsWarrantyHint {
                    Spacer().frame(height: .spacing8)
                    infoBox(textKey: "manual.warranty_hint")
                }

                Spacer().frame(height: .spacing16)
                fieldLabel("manual.memo", required: false)
                Spacer().frame(height: .spacing8)
                memoField
            }
        }
        .padding(.spacing16)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    private var needsWarrantyHint: Bool {
        if selectedWarranty == nil { return true }
        if selectedWarranty == 4 { return (Int(customMonthsText) ?? 0) <= 0 }
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

    // MARK: - 실물 영수증 보관 여부 (체크박스)

    private var physicalCard: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
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
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing16)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
        .overlay(
            RoundedRectangle(cornerRadius: .rounded2xl)
                .stroke(Color.gray200, lineWidth: 1)
        )
    }

    /// 기존 체크박스와 동일한 색상 체계(선택: brandPrimary / 비선택: gray300)를 그대로 적용.
    private var physicalCheckbox: some View {
        Button { physicalReceipt.toggle() } label: {
            ZStack {
                RoundedRectangle(cornerRadius: .roundedSm)
                    .fill(physicalReceipt ? Color.brandPrimary : Color.colorWhite)
                RoundedRectangle(cornerRadius: .roundedSm)
                    .stroke(physicalReceipt ? Color.brandPrimary : Color.gray300, lineWidth: 1.5)
                if physicalReceipt {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.colorWhite)
                }
            }
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 보증 정보 카드 (접이식)

    private var warrantyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsibleHeader("manual.warranty_section", expanded: $warrantyExpanded)

            if warrantyExpanded {
                Spacer().frame(height: .spacing16)
                VStack(alignment: .leading, spacing: .spacing16) {
                    BoatInputField(
                        text: Binding(
                            get: { brand },
                            set: { brand = String($0.prefix(Self.brandLimit)) }
                        ),
                        label: "manual.brand",
                        placeholder: "manual.brand_hint"
                    )
                    BoatInputField(
                        text: priceDisplayBinding,
                        label: "manual.price",
                        placeholder: "manual.price_hint",
                        keyboard: .numberPad
                    )
                    serialField
                }
            }
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
            TextField(
                "",
                text: Binding(
                    get: { serial },
                    set: { serial = String($0.prefix(Self.serialLimit)) }
                ),
                prompt: Text("manual.serial_hint").foregroundStyle(Color.gray400)
            )
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.gray900)
                .padding(.horizontal, .spacing16)
                .frame(height: 52)
                .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
                .overlay(
                    RoundedRectangle(cornerRadius: .roundedLg)
                        .stroke(Color.gray300, lineWidth: 1)
                )
        }
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
        // 이미지 미첨부 시 탭해서 경고 토스트를 띄워야 하므로 여기서 막지 않고 submit() 안에서 처리한다.
        .disabled(isSubmitting)
    }

    // MARK: - 작은 컴포넌트

    private func sectionTitle(_ key: LocalizedStringKey, required: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text(key)
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)
            if required {
                Text(" *")
                    .font(.pretendard(.bold, size: 18))
                    .foregroundStyle(Color.systemError)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func collapsibleHeader(_ key: LocalizedStringKey, expanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { expanded.wrappedValue.toggle() }
        } label: {
            HStack {
                Text(key)
                    .font(.pretendard(.bold, size: 18))
                    .foregroundStyle(Color.gray900)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.gray500)
                    .rotationEffect(.degrees(expanded.wrappedValue ? 180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    private func infoBox(text: String? = nil, textKey: LocalizedStringKey? = nil, systemIcon: String? = nil) -> some View {
        HStack(spacing: .spacing8) {
            if let systemIcon {
                Image(systemName: systemIcon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.brandPrimary)
            }
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
                .font(.pretendard(selected ? .semibold : .medium, size: 13))
                .foregroundStyle(selected ? Color.colorWhite : Color.gray700)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selected ? Color.brandPrimary : Color.clear, in: Capsule())
                .overlay(
                    Capsule().stroke(selected ? Color.clear : Color.gray300, lineWidth: 1)
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

    private var apiPaymentDate: String? {
        guard !purchaseDate.isEmpty else { return nil }
        return purchaseDate.replacingOccurrences(of: ".", with: "-")
    }

    /// "yyyy.MM.dd" → "yyyy-MM-dd" (서버 전송 포맷)
    private var apiExpiresOn: String? {
        expiresOnDisplay?.replacingOccurrences(of: ".", with: "-")
    }

    /// 카메라 실행 — 촬영 시점에 권한 확인/요청 (App Store 심사 가이드 준수).
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

    private func addImages(_ new: [UIImage]) {
        guard !new.isEmpty else { return }
        images.append(contentsOf: new.prefix(remainingSlots))
    }

    private func submit() {
        guard !isSubmitting else { return }
        guard !images.isEmpty else {
            toast.showError(String(localized: "manual.image_required"))
            return
        }
        guard canSubmit else { return }

        let sub = (selectedSubcategory == "기타" ? nil : selectedSubcategory)
        let fields = ReceiptCreateFields(
            itemName: productName.trimmingCharacters(in: .whitespaces),
            brandName: brand.trimmingCharacters(in: .whitespaces),
            paymentLocation: nil,
            paymentDate: apiPaymentDate,
            totalAmount: Int(price),
            periodMonths: totalWarrantyMonths,
            expiresOn: apiExpiresOn,
            category: selectedCategory.rawValue,
            subCategory: sub,
            memo: memo.trimmingCharacters(in: .whitespaces),
            requiresPhysicalReceipt: physicalReceipt
        )
        let imagesToUpload = images

        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                let receipt = try await ReceiptRepository.shared.createReceipt(images: imagesToUpload, fields: fields)
                completedReceipt = receipt
            } catch {
                toast.showError((error as? LocalizedError)?.errorDescription ?? String(localized: "receipt.register.fail"))
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
                addImages(loaded)
                galleryItems = []
            }
        }
    }
}



#Preview {
    ReceiptManualInputView(images: [], onBack: {})
        .environment(PermissionManager())
}
