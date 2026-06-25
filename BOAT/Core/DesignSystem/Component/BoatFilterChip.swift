//
//  BoatFilterChip.swift
//  BOAT
//
//  카테고리 필터 칩. Android BoatFilterChip 대응.
//  선택 시 brandPrimary 채움(흰 글씨), 미선택 시 연한 brand 배경(파란 글씨).
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
                    selected ? Color.brandPrimary : Color.brandQuaternary,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}
