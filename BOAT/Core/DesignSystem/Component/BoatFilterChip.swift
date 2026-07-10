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

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.pretendard(.medium, size: 14))
                .lineLimit(1)
                .foregroundStyle(selected ? Color.colorWhite : Color.brandPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    selected ? Color.brandPrimary : Color.colorWhite,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(Color.brandTertiary, lineWidth: selected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}
