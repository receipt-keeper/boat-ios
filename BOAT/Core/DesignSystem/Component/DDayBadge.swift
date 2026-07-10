//
//  DDayBadge.swift
//  BOAT
//
//  D-day(보증 잔여일) 뱃지 공용 컴포넌트. Android WarrantyDayBadge 대응.
//  앱 내 모든 D-day 표시는 이 컴포넌트로 통일한다(목록/상세/홈 등).
//
//  상태(dDay 기준):
//  - nil 또는 0 이하 → "만료" (회색)
//  - 30 이하        → "D-N" (빨강, 임박)
//  - 그 외          → "D-N" (파랑, 여유)
//

import SwiftUI

struct DDayBadge: View {
    let dDay: Int?

    /// 임박(빨강) 판정 기준일. 단일 출처: Receipt.expiringThresholdDays.
    private static let expiringThresholdDays = Receipt.expiringThresholdDays

    var body: some View {
        let style = Self.style(for: dDay)
        style.text
            .font(.pretendard(.medium, size: 13))
            .foregroundStyle(style.fg)
            .frame(minWidth: 58)
            .frame(height: 26)
            .padding(.horizontal, .spacing8)
            .background(style.bg, in: RoundedRectangle(cornerRadius: .roundedLg))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(style.border, lineWidth: 1)
            )
    }

    private static func style(for dDay: Int?) -> (text: Text, bg: Color, border: Color, fg: Color) {
        guard let dDay, dDay > 0 else {
            return (Text("receipt.list.expired"), .badgeExpiredBg, .badgeExpiredBorder, .badgeExpiredText)
        }
        if dDay <= expiringThresholdDays {
            return (Text("receipt.list.dday \(dDay)"), .badgeWarningBg, .badgeWarningBorder, .badgeWarningText)
        }
        return (Text("receipt.list.dday \(dDay)"), .badgeSafeBg, .badgeSafeBorder, .badgeSafeText)
    }
}

#Preview {
    VStack(spacing: 12) {
        DDayBadge(dDay: 120)
        DDayBadge(dDay: 29)
        DDayBadge(dDay: 0)
        DDayBadge(dDay: nil)
    }
    .padding()
}
