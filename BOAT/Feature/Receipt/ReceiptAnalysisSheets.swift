//
//  ReceiptAnalysisSheets.swift
//  BOAT
//
//  영수증 분석 관련 바텀시트 — 토큰 소진(NoToken) / 분석 실패(AnalysisFailed).
//  Android NoTokenBottomSheet / AnalysisFailedBottomSheet 대응.
//

import SwiftUI

// MARK: - 시트 종류

enum AnalysisSheet: Identifiable {
    case noToken
    case failed
    var id: Int { hashValue }
}

// MARK: - 토큰 소진 시트

struct NoTokenSheet: View {
    let onRecharge: () -> Void
    let onManualInput: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            noTokenIcon

            Spacer().frame(height: .spacing20)
            Text("receipt.token.title")
                .font(.pretendard(.bold, size: 22))
                .foregroundStyle(Color.gray900)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            Spacer().frame(height: .spacing8)
            Text("receipt.token.subtitle")
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray500)
                .multilineTextAlignment(.center)

            Spacer().frame(height: .spacing24)
            primaryButton("receipt.token.recharge", action: onRecharge)

            Spacer().frame(height: .spacing8)
            outlinedButton("receipt.token.manual", action: onManualInput)

            Spacer().frame(height: .spacing8)
            Button(action: onLater) {
                Text("receipt.token.later")
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray500)
                    .padding(.vertical, .spacing8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing24)
        .padding(.bottom, .spacing16)
        .frame(maxWidth: .infinity)
    }

    // 큰 스파클 + 작은 스파클 조합 아이콘
    private var noTokenIcon: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("icSparkle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .offset(x: -10, y: -10)

            Image("icSparkle")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
        .frame(width: 80, height: 80)
    }
}

// MARK: - 분석 실패 시트

struct AnalysisFailedSheet: View {
    let onManualInput: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            failedIcon

            Spacer().frame(height: .spacing20)
            Text("receipt.fail.title")
                .font(.pretendard(.bold, size: 22))
                .foregroundStyle(Color.gray900)
                .multilineTextAlignment(.center)

            Spacer().frame(height: .spacing8)
            Text("receipt.fail.subtitle")
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray500)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: .spacing20)
            Button(action: onManualInput) {
                Text("receipt.fail.manual")
                    .font(.pretendard(.bold, size: 15))
                    .foregroundStyle(Color.brandPrimary)
                    .underline()
                    .padding(.vertical, .spacing8)
            }
            .buttonStyle(.plain)

            Spacer().frame(height: .spacing8)
            primaryButton("receipt.fail.retry", action: onRetry)
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing24)
        .padding(.bottom, .spacing16)
        .frame(maxWidth: .infinity)
    }

    // 영수증 문서 아이콘 + 빨간 X 배지
    private var failedIcon: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 72, height: 72)

            ZStack {
                Circle()
                    .fill(Color.systemError)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color.colorWhite, lineWidth: 2)
                    )
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.colorWhite)
            }
            .offset(x: 4, y: 4)
        }
    }
}

// MARK: - 공통 버튼

private func primaryButton(_ label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.pretendard(.semibold, size: 16))
            .foregroundStyle(Color.colorWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.brandPrimary, in: RoundedRectangle(cornerRadius: .roundedXl))
    }
    .buttonStyle(.plain)
}

private func outlinedButton(_ label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.pretendard(.medium, size: 16))
            .foregroundStyle(Color.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedXl)
                    .stroke(Color.brandTertiary, lineWidth: 1)
            )
    }
    .buttonStyle(.plain)
}

// MARK: - Preview

#Preview("토큰 소진") {
    NoTokenSheet(onRecharge: {}, onManualInput: {}, onLater: {})
        .background(Color.colorWhite)
}

#Preview("분석 실패") {
    AnalysisFailedSheet(onManualInput: {}, onRetry: {})
        .background(Color.colorWhite)
}
