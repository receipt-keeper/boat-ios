//
//  ReceiptAddMenu.swift
//  BOAT
//
//  영수증 등록 FAB 메뉴 카드. Android ReceiptAddSheet 대응.
//  내용(가장 긴 항목) 크기에 맞춰지는 컴팩트 카드 — 스크림/위치는 호출부에서 처리.
//

import SwiftUI

struct ReceiptAddMenuCard: View {
    let onCamera: () -> Void
    let onGallery: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4) {
            menuItem(icon: "icCamera", label: "receipt.add.camera", action: onCamera)
            menuItem(icon: "icImage", label: "receipt.add.gallery", action: onGallery)
        }
        .padding(.vertical, .spacing20)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private func menuItem(
        icon: String,
        label: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: .spacing12) {
                Image(icon)
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray900)
                    .frame(width: 24, height: 24)
                Text(label)
                    .font(.pretendard(.medium, size: 16))
                    .foregroundStyle(Color.gray900)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, .spacing24)
            .padding(.vertical, .spacing12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
