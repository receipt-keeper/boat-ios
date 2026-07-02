//
//  ReceiptAnalysisResultView.swift
//  BOAT
//
//  OCR 분석 성공 직후 보여주는 임시 결과 화면. 응답 필드를 그대로 나열한다.
//  (정식 등록 폼 연결 전까지의 단순 확인용 화면)
//

import SwiftUI

struct ReceiptAnalysisResultView: View {

    let result: OcrAnalysis
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: .spacing16) {
                    row("제품명", result.itemName)
                    row("브랜드", result.brandName)
                    row("구매처", result.paymentLocation)
                    row("구매일", result.paymentDate)
                    row("금액", result.totalAmount.map { "\($0.formattedWithComma)원" })
                    row("AS 기간", result.periodMonths.map { "\($0)개월" })
                    row("AS 만료일", result.expiresOn)
                    row("카테고리", result.category)
                    row("검수 필요", result.needsReview.map { $0 ? "예" : "아니오" })

                    if let warnings = result.warnings, !warnings.isEmpty {
                        Divider().padding(.vertical, .spacing4)
                        Text("경고")
                            .font(.pretendard(.semibold, size: 13))
                            .foregroundStyle(Color.gray500)
                        ForEach(Array(warnings.enumerated()), id: \.offset) { _, warning in
                            Text("• \(warning)")
                                .font(.pretendard(.regular, size: 14))
                                .foregroundStyle(Color.systemError)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .spacing20)
                .padding(.vertical, .spacing16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
    }

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

            Text("분석 결과")
                .font(.pretendard(.semibold, size: 17))
                .foregroundStyle(Color.gray900)
                .padding(.leading, .spacing4)

            Spacer()
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    /// 라벨 + 값 한 줄. 값이 없으면 "-" 표기.
    private func row(_ label: String, _ value: String?) -> some View {
        HStack(alignment: .top, spacing: .spacing12) {
            Text(label)
                .font(.pretendard(.medium, size: 14))
                .foregroundStyle(Color.gray500)
                .frame(width: 80, alignment: .leading)

            Text(value ?? "-")
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(value == nil ? Color.gray400 : Color.gray900)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ReceiptAnalysisResultView(
        result: OcrAnalysis(
            itemName: "삼성 냉장고 875L",
            brandName: "삼성",
            paymentLocation: "전자랜드",
            paymentDate: "2024-05-26",
            totalAmount: 5137000,
            periodMonths: 12,
            expiresOn: "2025-05-26",
            category: "가전",
            needsReview: true,
            warnings: ["무상 AS 기간을 찾지 못해 12개월 기본값을 적용했습니다."]
        ),
        onBack: {}
    )
}
