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
    case unsupportedReceipt
    var id: Int { hashValue }
}

// 영수증 문서 아이콘 + 빨간 X 배지 — 분석 실패/미지원 시트가 공유하는 아이콘.
private struct ReceiptErrorIcon: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 32, height: 32)

            ZStack {
                Circle()
                    .fill(Color.systemError)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.colorWhite, lineWidth: 1.5)
                    )
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color.colorWhite)
            }
            .offset(x: 3, y: 3)
        }
    }
}

// MARK: - 토큰 소진 시트

struct NoTokenSheet: View {
    /// 무료 충전 프로모션 수령 가능 여부 — false면 충전 버튼/안내 박스 없이 직접 입력만 노출.
    let canRecharge: Bool
    let onRecharge: () -> Void
    let onManualInput: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            closeButton

            Spacer().frame(height: .spacing4)
            noTokenIcon
                .frame(maxWidth: .infinity, alignment: canRecharge ? .leading : .center)

            Spacer().frame(height: .spacing16)
            Text("receipt.token.title")
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(Color.gray900)
                .multilineTextAlignment(canRecharge ? .leading : .center)
                .frame(maxWidth: .infinity, alignment: canRecharge ? .leading : .center)

            Spacer().frame(height: .spacing8)
            if canRecharge {
                (Text("receipt.token.subtitle_prefix")
                    + Text("receipt.token.subtitle_emphasis")
                    + Text("receipt.token.subtitle_suffix"))
                    .font(.pretendard(.bold, size: 18))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer().frame(height: .spacing24)
                noticeBox
            } else {
                Text("receipt.token.subtitle_none")
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray500)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer().frame(height: .spacing24)
            if canRecharge {
                primaryButton("receipt.token.recharge", action: onRecharge)
                Spacer().frame(height: .spacing8)
                outlinedButton("receipt.token.manual", action: onManualInput)
            } else {
                primaryButton("receipt.token.manual", action: onManualInput)
            }
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing8)
        .padding(.bottom, .spacing16)
        .frame(maxWidth: .infinity)
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.gray900)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // 반짝이는 스파클 GIF
    private var noTokenIcon: some View {
        GifImageView(name: "shiny_white")
            .frame(width: 32, height: 32)
    }

    // 무료 분석 유효기간 안내 박스 (충전 가능 시에만 노출)
    private var noticeBox: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            Text("receipt.token.notice.title")
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(Color.gray900)

            HStack(alignment: .top, spacing: .spacing4) {
                Text("•")
                (Text("receipt.token.notice.body_prefix")
                    + Text("receipt.token.notice.body_emphasis").foregroundColor(Color.brandPrimary)
                    + Text("receipt.token.notice.body_suffix"))
            }
            .font(.pretendard(.regular, size: 13))
            .foregroundStyle(Color.gray600)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray50, in: RoundedRectangle(cornerRadius: .roundedLg))
    }
}

// MARK: - 분석 실패 시트

struct AnalysisFailedSheet: View {
    let onManualInput: () -> Void
    let onRetry: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                ReceiptErrorIcon()
                Spacer()
                closeButton
            }

            Spacer().frame(height: .spacing16)
            Text("receipt.fail.title")
                .font(.pretendard(.bold, size: 20))
                .foregroundStyle(Color.gray900)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: .spacing8)
            Text("receipt.fail.subtitle")
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: .spacing16)
            noticeBox

            Spacer().frame(height: .spacing24)
            primaryButton("receipt.fail.retry", action: onRetry)
            Spacer().frame(height: .spacing8)
            outlinedButton("receipt.fail.manual", action: onManualInput)
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing8)
        .padding(.bottom, .spacing16)
        .frame(maxWidth: .infinity)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.gray900)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // 촬영 유의사항 안내 박스
    private var noticeBox: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            Text("receipt.token.notice.title")
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(Color.gray900)

            VStack(alignment: .leading, spacing: 4) {
                noticeBullet("receipt.fail.notice.bullet1")
                noticeBullet("receipt.fail.notice.bullet2")
                noticeBullet("receipt.fail.notice.bullet3")
            }
        }
        .padding(.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray50, in: RoundedRectangle(cornerRadius: .roundedLg))
    }

    private func noticeBullet(_ key: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: .spacing4) {
            Text("•")
            Text(key)
        }
        .font(.pretendard(.regular, size: 13))
        .foregroundStyle(Color.gray600)
        .lineSpacing(3)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - 미지원 영수증 시트 (UNSUPPORTED_RECEIPT)

/// 서버가 OCR 분석 응답으로 UNSUPPORTED_RECEIPT 코드를 내려줄 때 노출 — Toast 대신 시트로 안내.
/// AnalysisFailedSheet와 동일한 구조(아이콘/닫기 버튼/안내 박스/CTA)를 재사용한다.
struct UnsupportedReceiptSheet: View {
    let onRetry: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                ReceiptErrorIcon()
                Spacer()
                closeButton
            }

            Spacer().frame(height: .spacing16)
            Text("receipt.unsupported.title")
                .font(.pretendard(.bold, size: 20))
                .foregroundStyle(Color.gray900)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: .spacing8)
            Text("receipt.unsupported.subtitle")
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: .spacing16)
            noticeBox

            Spacer().frame(height: .spacing24)
            primaryButton("receipt.unsupported.retry", action: onRetry)
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing8)
        .padding(.bottom, .spacing16)
        .frame(maxWidth: .infinity)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.gray900)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // 현재 등록 가능한 영수증 안내 박스
    private var noticeBox: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            Text("receipt.unsupported.notice.title")
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(Color.gray900)

            VStack(alignment: .leading, spacing: 4) {
                noticeBullet("receipt.unsupported.notice.bullet1")
                noticeBullet("receipt.unsupported.notice.bullet2")
                noticeBullet("receipt.unsupported.notice.bullet3")
                noticeBullet("receipt.unsupported.notice.bullet4")
            }
        }
        .padding(.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray50, in: RoundedRectangle(cornerRadius: .roundedLg))
    }

    private func noticeBullet(_ key: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: .spacing4) {
            Text("•")
            Text(key)
        }
        .font(.pretendard(.regular, size: 13))
        .foregroundStyle(Color.gray600)
        .lineSpacing(3)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - 공통 버튼

private func primaryButton(_ label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.pretendard(.medium, size: 16))
            .foregroundStyle(Color.colorWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.brandPrimary, in: RoundedRectangle(cornerRadius: .roundedLg))
    }
    .buttonStyle(.plain)
}

private func outlinedButton(_ label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.pretendard(.medium, size: 16))
            .foregroundStyle(Color.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(Color.brandTertiary, lineWidth: 1)
            )
    }
    .buttonStyle(.plain)
}

// MARK: - Preview

#Preview("토큰 소진 - 충전 가능") {
    NoTokenSheet(canRecharge: true, onRecharge: {}, onManualInput: {}, onClose: {})
        .background(Color.colorWhite)
}

#Preview("토큰 소진 - 충전 불가") {
    NoTokenSheet(canRecharge: false, onRecharge: {}, onManualInput: {}, onClose: {})
        .background(Color.colorWhite)
}

#Preview("분석 실패") {
    AnalysisFailedSheet(onManualInput: {}, onRetry: {}, onClose: {})
        .background(Color.colorWhite)
}

#Preview("미지원 영수증") {
    UnsupportedReceiptSheet(onRetry: {}, onClose: {})
        .background(Color.colorWhite)
}
