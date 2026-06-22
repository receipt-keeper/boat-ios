//
//  ReceiptAddMenu.swift
//  BOAT
//
//  영수증 등록 FAB 메뉴. Android ReceiptAddSheet 대응.
//  스크림(탭 시 닫힘) + 흰 카드(사진으로 찍기 / 갤러리에서 불러오기), FAB 위에 위치.
//

import SwiftUI

struct ReceiptAddMenu: View {
    let onDismiss: () -> Void
    let onCamera: () -> Void
    let onGallery: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 스크림 — 전체 화면(탭바 포함) 딤 처리, 탭하면 닫힘
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // 메뉴 카드 — FAB 위쪽 우측에 배치
            VStack(alignment: .leading, spacing: .spacing4) {
                menuItem(icon: "icCamera", label: "receipt.add.camera", action: onCamera)
                menuItem(icon: "icImage", label: "receipt.add.gallery", action: onGallery)
            }
            .padding(.vertical, .spacing20)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            .padding(.trailing, .spacing16)
            .padding(.bottom, 84) // FAB(56) + bottom 16 + gap 12 위로
        }
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
                Spacer(minLength: 0)
            }
            .padding(.horizontal, .spacing24)
            .padding(.vertical, .spacing12)
        }
        .buttonStyle(.plain)
    }
}
