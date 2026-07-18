//
//  ReceiptDetailView.swift
//  BOAT
//
//  영수증 상세 화면. GET /api/v1/receipts/{receiptId}
//  제품 이미지 + 기본 정보(제품명/구매일/무상 AS 만료일/메모) + 실물 영수증 안내 +
//  보증 정보(브랜드/구매가격/시리얼) + 원본 영수증 + 공식 AS 접수 CTA.
//

import SwiftUI

struct ReceiptDetailView: View {

    let receiptId: String
    let onBack: () -> Void
    /// 삭제 완료 콜백 — 상위(목록)에서 목록 갱신 + 삭제 토스트 + 상세 닫기 처리
    var onDeleted: () -> Void = {}
    /// true면 상단 좌측 버튼을 뒤로가기(←) 대신 닫기(X)로 표시.
    /// 등록 완료 화면의 "보러가기"처럼 이전 화면으로 돌아갈 수 없는 진입 경로에서 사용.
    var showCloseButton: Bool = false

    @Environment(\.openURL) private var openURL

    @State private var receipt: Receipt?
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var toast = BoatToastState()
    // 케밥 메뉴(수정/삭제) + 삭제 확인 다이얼로그
    @State private var showActionSheet = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showEditView = false
    // 원본 영수증 썸네일 탭 → 전체화면 이미지 뷰어
    @State private var showViewer = false
    @State private var viewerIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            topBar

            if let receipt {
                ScrollView {
                    content(receipt)
                }
            } else if isLoading {
                ScrollView {
                    skeletonContent
                }
            } else {
                errorView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        // 케밥 → 수정/삭제 액션 시트 (스크림 + 하단 카드 + 닫기)
        .overlay {
            if showActionSheet {
                actionSheetOverlay
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showActionSheet)
        // 삭제 확인 다이얼로그
        .boatDialog(
            isPresented: $showDeleteConfirm,
            title: "detail.delete_confirm_title",
            message: "detail.delete_confirm_message",
            confirmText: "detail.menu_delete",
            confirmColor: .brandPrimary,
            cancelText: "common.cancel",
            onConfirm: { performDelete() }
        )
        .task { await load() }
        .boatToastHost(toast)
        // 케밥 → 수정하기
        .fullScreenCover(isPresented: $showEditView) {
            if let receipt {
                ReceiptEditView(
                    receipt: receipt,
                    onBack: { showEditView = false },
                    onUpdated: {
                        showEditView = false
                        Task { await load() }
                        toast.show(String(localized: "detail.updated_toast"), type: .info)
                    }
                )
            }
        }
    }

    // MARK: - 케밥 액션 시트 (수정하기 / 삭제하기 / 닫기)

    private var actionSheetOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { showActionSheet = false }

            VStack(spacing: .spacing8) {
                VStack(spacing: 0) {
                    actionRow("detail.menu_edit", color: .brandPrimary) {
                        showActionSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            showEditView = true
                        }
                    }
                    Rectangle().fill(Color.gray200).frame(height: 1)
                    actionRow("detail.menu_delete", color: .systemError) {
                        showActionSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            showDeleteConfirm = true
                        }
                    }
                }
                .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))

                actionRow("detail.menu_close", color: .gray900) { showActionSheet = false }
                    .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
            }
            .padding(.horizontal, .spacing16)
            .padding(.bottom, .spacing16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func actionRow(_ key: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(key)
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top Bar (뒤로 + 케밥)

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(showCloseButton ? "icon_close" : "icChevronLeft")
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray900)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 케밥 → 수정/삭제 액션 시트
            Button {
                showActionSheet = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.gray900)
                    .rotationEffect(.degrees(90))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    // MARK: - 본문

    private func content(_ r: Receipt) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 제품 이미지 히어로 카드
            deviceImageBanner(r)

            Spacer().frame(height: .spacing24)

            // 제품명 / 구매일 / 무상 AS 만료일 / 메모
            VStack(alignment: .leading, spacing: .spacing20) {
                labeledValue("detail.product_name", r.itemName)
                hairline
                labeledValue("detail.purchase_date", dotDate(r.paymentDate))
                hairline
                expiryRow(r)
                hairline
                memoSection(r)
            }
            .padding(.horizontal, .spacing20)

            Spacer().frame(height: .spacing24)

            // 실물 영수증 보관 여부 (저장값 라디오 표시)
            sectionBand
            physicalSection(r)
                .padding(.horizontal, .spacing20)
                .padding(.top, .spacing24)
                .padding(.bottom, .spacing8)

            // 보증 정보
            sectionBand
            VStack(alignment: .leading, spacing: .spacing20) {
                Text("detail.warranty_info")
                    .font(.pretendard(.bold, size: 18))
                    .foregroundStyle(Color.gray900)
                labeledValue("detail.brand", r.brandName ?? "-")
                hairline
                labeledValue("detail.price", priceText(r.totalAmount))
                hairline
                serialRow(r)
            }
            .padding(.horizontal, .spacing20)
            .padding(.top, .spacing24)
            .padding(.bottom, .spacing8)

            // 원본 영수증 + 공식 AS 접수 CTA (스크롤 콘텐츠에 포함 — 하단 고정 아님)
            sectionBand
            VStack(alignment: .leading, spacing: 0) {
                originalReceiptSection(r)
                Spacer().frame(height: .spacing20)
                supportButton(r)
            }
            .padding(.horizontal, .spacing20)
            .padding(.top, .spacing24)

            Spacer().frame(height: .spacing24)
        }
    }

    // 대표 이미지 히어로 카드 — 상→하 연한 블루 그라데이션 배경 + 테두리(Android 16:9 카드 대응)
    private func deviceImageBanner(_ r: Receipt) -> some View {
        RoundedRectangle(cornerRadius: .rounded2xl)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#E5F0FF"), Color(hex: "#F6FAFF")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: .rounded2xl)
                    .stroke(Color.brandQuinary, lineWidth: 1)
            )
            .overlay {
                Image(r.deviceImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            }
            .padding(.horizontal, .spacing20)
            .padding(.top, .spacing8)
    }

    // MARK: - 실물 영수증 보관 여부

    private func physicalSection(_ r: Receipt) -> some View {
        let kept = r.requiresPhysicalReceipt == true
        return VStack(alignment: .leading, spacing: .spacing8) {
            Text("manual.physical_section")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)
            Text(kept ? "detail.physical_kept" : "detail.physical_not_kept")
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.brandPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 시리얼 넘버 (라벨 + 도움말(?))
    private func serialRow(_ r: Receipt) -> some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            HStack(spacing: 6) {
                Text("detail.serial")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundStyle(Color.gray500)
                InfoTooltip(message: "manual.serial_help")
            }
            Text(r.serialNumber ?? "-")
                .font(.pretendard(.medium, size: 17))
                .foregroundStyle(Color.gray900)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 라벨(위) + 값(아래)
    private func labeledValue(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            Text(label)
                .font(.pretendard(.regular, size: 13))
                .foregroundStyle(Color.gray500)
            Text(value)
                .font(.pretendard(.medium, size: 17))
                .foregroundStyle(Color.gray900)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 무상 AS 만료일 + D-day 배지
    private func expiryRow(_ r: Receipt) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: .spacing8) {
                Text("detail.expiry")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundStyle(Color.gray500)
                Text(dotDate(r.expiresOn))
                    .font(.pretendard(.medium, size: 17))
                    .foregroundStyle(Color.gray900)
            }
            Spacer()
            DDayBadge(dDay: r.warrantyDDay)
        }
    }

    private func memoSection(_ r: Receipt) -> some View {
        let memo = r.memo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return VStack(alignment: .leading, spacing: .spacing8) {
            Text("detail.memo")
                .font(.pretendard(.regular, size: 13))
                .foregroundStyle(Color.gray500)
            Text(memo)
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.gray800)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .padding(.spacing16)
                .background(Color.gray50, in: RoundedRectangle(cornerRadius: .roundedLg))
        }
    }

    private func originalReceiptSection(_ r: Receipt) -> some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            Text("detail.original_receipt")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)

            let files = r.receiptFiles ?? []
            if files.isEmpty {
                receiptPlaceholderBox
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacing12) {
                        ForEach(Array(files.enumerated()), id: \.element.fileId) { index, file in
                            receiptFileBox(file)
                                .onTapGesture {
                                    viewerIndex = index
                                    showViewer = true
                                }
                        }
                    }
                }
                .fullScreenCover(isPresented: $showViewer) {
                    ImageViewerScreen(
                        items: files.map { .remote($0) },
                        initialIndex: viewerIndex,
                        onClose: { showViewer = false }
                    )
                }
            }
        }
    }

    private func receiptFileBox(_ file: ReceiptFile) -> some View {
        RoundedRectangle(cornerRadius: .roundedLg)
            .fill(Color.gray50)
            .frame(width: 104, height: 104)
            .overlay { AuthenticatedImage(contentPath: file.contentPath) }
            .clipShape(RoundedRectangle(cornerRadius: .roundedLg))
            .contentShape(RoundedRectangle(cornerRadius: .roundedLg))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(Color.gray200, lineWidth: 1)
            )
    }

    private var receiptPlaceholderBox: some View {
        RoundedRectangle(cornerRadius: .roundedLg)
            .fill(Color.colorWhite)
            .frame(width: 104, height: 104)
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(Color.gray200, lineWidth: 1)
            )
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.gray300)
            }
    }

    // MARK: - 공식 AS 접수 링크 (연한 블루 링크 스타일, 원본 영수증 섹션 하단 — 스크롤 콘텐츠 내부)

    private func supportButton(_ r: Receipt) -> some View {
        let url = r.supportUrl.flatMap { URL(string: $0) }
        return Button {
            if let url { openURL(url) }
        } label: {
            HStack(spacing: .spacing8) {
                Text("detail.support")
                    .font(.pretendard(.semibold, size: 15))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
            }
            .padding(.horizontal, .spacing16)
            .padding(.vertical, 16)
            .background(Color.brandSenary, in: RoundedRectangle(cornerRadius: .roundedXl))
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
    }

    // MARK: - 로딩 스켈레톤 (API 응답 전까지 실제 콘텐츠 레이아웃을 셔머로 흉내)

    /// 라벨 폭(96)/값 폭 비율(0.62)은 Android ReceiptDetailSkeleton과 동일.
    private var contentWidth: CGFloat { UIScreen.main.bounds.width - .spacing20 * 2 }

    private var skeletonContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 대표 이미지 히어로 카드
            ShimmerBox(cornerRadius: .rounded2xl)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .padding(.horizontal, .spacing20)
                .padding(.top, .spacing8)

            Spacer().frame(height: .spacing24)
            VStack(alignment: .leading, spacing: 0) {
                // 필드 3개 (라벨 바 + 값 바)
                ForEach(0..<3, id: \.self) { _ in
                    ShimmerBox().frame(width: 96, height: 13)
                    Spacer().frame(height: 10)
                    ShimmerBox().frame(width: contentWidth * 0.62, height: 18)
                    Spacer().frame(height: .spacing20)
                }
                // 메모 라벨 + 박스
                ShimmerBox().frame(width: 60, height: 13)
                Spacer().frame(height: .spacing8)
                ShimmerBox(cornerRadius: .roundedLg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
            }
            .padding(.horizontal, .spacing20)

            // 실물 영수증 보관 여부 섹션
            Spacer().frame(height: .spacing24)
            sectionBand
            VStack(alignment: .leading, spacing: 0) {
                ShimmerBox().frame(width: 140, height: 18)
                Spacer().frame(height: .spacing16)
                ShimmerBox().frame(width: 110, height: 14)
                Spacer().frame(height: .spacing12)
                ShimmerBox().frame(width: 90, height: 14)
            }
            .padding(.horizontal, .spacing20)
            .padding(.vertical, .spacing20)

            // 보증 정보 섹션 (필드 2개)
            sectionBand
            VStack(alignment: .leading, spacing: 0) {
                ShimmerBox().frame(width: 120, height: 18)
                Spacer().frame(height: .spacing16)
                ForEach(0..<2, id: \.self) { _ in
                    ShimmerBox().frame(width: 96, height: 13)
                    Spacer().frame(height: 10)
                    ShimmerBox().frame(width: contentWidth * 0.5, height: 18)
                    Spacer().frame(height: .spacing16)
                }
            }
            .padding(.horizontal, .spacing20)
            .padding(.vertical, .spacing20)

            // 원본 영수증 섹션 (제목 + 썸네일 3개) + 공식 AS 접수 버튼
            sectionBand
            VStack(alignment: .leading, spacing: 0) {
                ShimmerBox().frame(width: 120, height: 18)
                    .padding(.horizontal, .spacing20)

                Spacer().frame(height: .spacing16)
                HStack(spacing: .spacing12) {
                    ForEach(0..<3, id: \.self) { _ in
                        ShimmerBox(cornerRadius: .rounded2xl)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal, .spacing20)

                Spacer().frame(height: .spacing20)
                ShimmerBox(cornerRadius: .roundedXl)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .padding(.horizontal, .spacing20)
            }
            .padding(.vertical, .spacing20)

            Spacer().frame(height: .spacing24)
        }
    }

    private var errorView: some View {
        VStack(spacing: .spacing12) {
            Text("error.api.unknown")
                .font(.pretendard(.medium, size: 15))
                .foregroundStyle(Color.gray500)
            Button {
                Task { await load() }
            } label: {
                Text("common.confirm")
                    .font(.pretendard(.semibold, size: 15))
                    .foregroundStyle(Color.brandPrimary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 컴포넌트

    private var hairline: some View {
        Rectangle().fill(Color.gray200).frame(height: 1)
    }

    private var sectionBand: some View {
        Rectangle().fill(Color.gray100).frame(height: 8).frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    /// "yyyy-MM-dd" → "yyyy.MM.dd" (없으면 "-")
    private func dotDate(_ ymd: String?) -> String {
        guard let ymd, !ymd.isEmpty else { return "-" }
        return ymd.replacingOccurrences(of: "-", with: ".")
    }

    /// 금액 → "385,000 원" (없으면 "-")
    private func priceText(_ amount: Int?) -> String {
        guard let amount else { return "-" }
        return "\(amount.formattedWithComma) 원"
    }

    // MARK: - Load

    private func load() async {
        isLoading = true
        loadFailed = false
        do {
            receipt = try await ReceiptRepository.shared.fetchReceiptDetail(id: receiptId)
        } catch {
            loadFailed = true
        }
        isLoading = false
    }

    /// DELETE /api/v1/receipts/{id} — 성공 시 상위(목록)에 위임(목록 갱신 + 삭제 토스트 + 상세 닫기).
    private func performDelete() {
        guard !isDeleting else { return }
        Task {
            isDeleting = true
            defer { isDeleting = false }
            do {
                try await ReceiptRepository.shared.deleteReceipt(id: receiptId)
                onDeleted()  // 목록 동기화 + 삭제 토스트 (상위)
                onBack()     // 상세 닫기
            } catch {
                toast.showError(String(localized: "receipt.delete.fail"))
            }
        }
    }
}
