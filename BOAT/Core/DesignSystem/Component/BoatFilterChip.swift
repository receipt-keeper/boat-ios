//
//  BoatFilterChip.swift
//  BOAT
//
//  카테고리 필터 칩. Android BoatFilterChip 대응.
//  선택: brandPrimary 채움 + 흰 글씨(테두리 없음) / 미선택: 흰 배경 + 파란 글씨 + 옅은 파란 테두리.
//

import SwiftUI

struct BoatFilterChip: View {
    let label: LocalizedStringKey
    let selected: Bool
    let onTap: () -> Void

    private let chipBlue = Color(hex: "#3B82F6")
    // 옅은 하늘색(#BFDBFE) 1pt로는 흰 배경 위에서 거의 안 보여, 눈에 띄게 진한 톤 + 두께로 보정.
    private let chipBorder = Color(hex: "#93C5FD")

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.pretendard(.medium, size: 14))
                .lineLimit(1)
                .foregroundStyle(selected ? Color.colorWhite : chipBlue)
                .padding(.horizontal, .spacing20)
                .padding(.vertical, .spacing8)
                .frame(height: 37)
                .background(
                    selected ? chipBlue : Color.colorWhite,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(chipBorder, lineWidth: selected ? 0 : 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}
