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

    @Environment(\.openURL) private var openURL

    @State private var receipt: Receipt?
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var toast = BoatToastState()

    var body: some View {
        VStack(spacing: 0) {
            topBar

            if let receipt {
                ScrollView {
                    content(receipt)
                }
                supportButton(receipt)
            } else if isLoading {
                loadingView
            } else {
                errorView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        .task { await load() }
        .boatToastHost(toast)
    }

    // MARK: - Top Bar (뒤로 + 수정)

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

            // TODO: 영수증 수정 화면 연결 (편집 API/화면 준비되면 교체)
            Button {
                // TODO: 수정 화면으로 이동
            } label: {
                Text("detail.edit")
                    .font(.pretendard(.medium, size: 16))
                    .foregroundStyle(Color.brandPrimary)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    // MARK: - 본문

    private func content(_ r: Receipt) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 제품 이미지 카드
            deviceImageCard(r)
                .padding(.horizontal, .spacing20)
                .padding(.top, .spacing8)

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

            // 실물 영수증 필요 (requiresPhysicalReceipt == true)
            if r.requiresPhysicalReceipt == true {
                sectionBand
                VStack(alignment: .leading, spacing: .spacing12) {
                    Text("detail.physical_receipt_title")
                        .font(.pretendard(.bold, size: 18))
                        .foregroundStyle(Color.gray900)
                    Text("detail.physical_receipt_desc")
                        .font(.pretendard(.semibold, size: 15))
                        .foregroundStyle(Color.brandPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .spacing20)
                .padding(.vertical, .spacing24)
            }

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
                labeledValue("detail.serial", r.serialNumber ?? "-")
            }
            .padding(.horizontal, .spacing20)
            .padding(.top, .spacing24)
            .padding(.bottom, .spacing8)

            // 원본 영수증
            sectionBand
            originalReceiptSection(r)
                .padding(.horizontal, .spacing20)
                .padding(.top, .spacing24)

            Spacer().frame(height: .spacing24)
        }
    }

    private func deviceImageCard(_ r: Receipt) -> some View {
        RoundedRectangle(cornerRadius: .rounded2xl)
            .fill(Color.brandSenary)
            .frame(height: 200)
            .overlay {
                Image(r.deviceImageName)
                    .resizable()
                    .scaledToFit()
                    .padding(40)
            }
            .overlay(
                RoundedRectangle(cornerRadius: .rounded2xl)
                    .stroke(Color.brandTertiary, lineWidth: 1.5)
            )
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
            ddayBadge(r)
        }
    }

    @ViewBuilder
    private func ddayBadge(_ r: Receipt) -> some View {
        switch r.warrantyBadge {
        case .safe(let dDay):
            badge(Text("receipt.list.dday \(dDay)"), bg: .badgeSafeBg, border: .badgeSafeBorder, fg: .badgeSafeText)
        case .expiring(let dDay):
            badge(Text("receipt.list.dday \(dDay)"), bg: .badgeWarningBg, border: .badgeWarningBorder, fg: .badgeWarningText)
        case .expired:
            badge(Text("receipt.list.expired"), bg: .badgeExpiredBg, border: .badgeExpiredBorder, fg: .badgeExpiredText)
        }
    }

    private func badge(_ text: Text, bg: Color, border: Color, fg: Color) -> some View {
        text
            .font(.pretendard(.bold, size: 13))
            .foregroundStyle(fg)
            .padding(.horizontal, .spacing12)
            .padding(.vertical, 6)
            .background(bg, in: Capsule())
            .overlay(Capsule().stroke(border, lineWidth: 1))
            .fixedSize()
    }

    private func memoSection(_ r: Receipt) -> some View {
        let memo = r.memo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isEmpty = memo.isEmpty
        return VStack(alignment: .leading, spacing: .spacing8) {
            Text("detail.memo")
                .font(.pretendard(.regular, size: 13))
                .foregroundStyle(Color.gray500)
            Text(isEmpty ? String(localized: "detail.memo_placeholder") : memo)
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(isEmpty ? Color.gray400 : Color.gray800)
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

            // TODO: 파일 서빙 URL 계약 확정 시 receiptFileId → 실제 이미지 로드로 교체.
            //       현재는 첨부 수만큼 플레이스홀더 박스 노출.
            let ids = r.receiptFileIds ?? []
            if ids.isEmpty {
                receiptPlaceholderBox
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacing12) {
                        ForEach(Array(ids.enumerated()), id: \.offset) { _, _ in
                            receiptPlaceholderBox
                        }
                    }
                }
            }
        }
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

    // MARK: - 하단 CTA (공식 AS 접수 → supportUrl)

    private func supportButton(_ r: Receipt) -> some View {
        let url = r.supportUrl.flatMap { URL(string: $0) }
        return Button {
            if let url { openURL(url) }
        } label: {
            Text("detail.support")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(url != nil ? Color.colorWhite : Color.gray500)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    url != nil ? Color.brandPrimary : Color.gray200,
                    in: RoundedRectangle(cornerRadius: .roundedXl)
                )
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing12)
        .padding(.bottom, .spacing8)
    }

    // MARK: - 상태 뷰

    private var loadingView: some View {
        ProgressView()
            .tint(Color.brandPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}
