//
//  ReceiptPromoSheet.swift
//  BOAT
//
//  마이페이지 "영수증 분석 N회 남음" 배너의 [보기] 탭 시 뜨는 바텀시트.
//  오픈 이벤트(무료 분석 지급) 안내 + 영수증 등록 유도.
//

import SwiftUI

struct ReceiptPromoSheet: View {
    let onClose: () -> Void
    let onRegister: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.gray900)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer().frame(height: .spacing8)

            GifImageView(name: "shiny_white")
                .frame(width: 32, height: 32)

            Spacer().frame(height: .spacing16)

            Text("mypage.promo.title")
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(Color.gray900)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: .spacing20)

            eventInfoBox

            Spacer().frame(height: .spacing24)

            Button(action: onRegister) {
                Text("mypage.promo.register")
                    .font(.pretendard(.semibold, size: 16))
                    .foregroundStyle(Color.colorWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.brandPrimary, in: RoundedRectangle(cornerRadius: .roundedXl))
            }
            .buttonStyle(.plain)

            Spacer().frame(height: .spacing16)
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing16)
        .frame(maxWidth: .infinity)
    }

    private var eventInfoBox: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            Text("mypage.promo.event_title")
                .font(.pretendard(.bold, size: 15))
                .foregroundStyle(Color.brandPrimary)
                .underline()

            VStack(alignment: .leading, spacing: .spacing8) {
                bullet(prefix: "mypage.promo.bullet1_prefix", emphasis: "mypage.promo.emphasis_free5", suffix: "mypage.promo.bullet1_suffix")
                bullet(prefix: "mypage.promo.bullet2_prefix", emphasis: "mypage.promo.emphasis_free5", suffix: "mypage.promo.bullet2_suffix")
                bullet(prefix: "mypage.promo.bullet3_prefix", emphasis: "mypage.promo.emphasis_extra5", suffix: "mypage.promo.bullet3_suffix")
            }
        }
        .padding(.spacing20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray50, in: RoundedRectangle(cornerRadius: .roundedLg))
    }

    /// 밑줄 강조 구간(무료 분석 5회 / 추가 5회)만 브랜드 컬러 + 밑줄을 적용한 불릿 텍스트.
    private func bullet(prefix: LocalizedStringKey, emphasis: LocalizedStringKey, suffix: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: .spacing8) {
            Circle()
                .fill(Color.gray600)
                .frame(width: 4, height: 4)
                .padding(.top, 8)
            (Text(prefix)
                + Text(emphasis).foregroundColor(Color.brandPrimary).fontWeight(.bold).underline()
                + Text(suffix))
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray700)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ReceiptPromoSheet(onClose: {}, onRegister: {})
        .background(Color.colorWhite)
}
