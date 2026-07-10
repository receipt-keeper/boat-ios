//
//  PhotoSourceSheet.swift
//  BOAT
//
//  사진 첨부 방법 선택 하단 액션 시트(디자인 가이드). Android PhotoSourceSheet 대응.
//  "카메라로 촬영하기 / 갤러리에서 불러오기" 옵션 그룹 카드 + 별도 "닫기" 카드. scrim 탭 시 닫힌다.
//
//  홈 FAB용 ReceiptAddMenuCard(FAB 위 앵커 팝업)와 달리, 화면 하단 전체 폭 액션 시트가
//  필요한 영수증 등록/수정/직접입력 화면에서 사용한다.
//

import SwiftUI

struct PhotoSourceSheet: View {
    let onCamera: () -> Void
    let onGallery: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: .spacing8) {
                VStack(spacing: 0) {
                    actionRow("receipt.register.camera", color: .brandPrimary, action: onCamera)
                    Rectangle().fill(Color.gray200).frame(height: 1)
                    actionRow("receipt.register.gallery", color: .brandPrimary, action: onGallery)
                }
                .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))

                actionRow("detail.menu_close", color: .gray900, action: onDismiss)
                    .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
            }
            .padding(.horizontal, .spacing12)
            .padding(.bottom, .spacing12)
        }
    }

    private func actionRow(_ key: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(key)
                .font(.pretendard(.semibold, size: 17))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PhotoSourceSheet(onCamera: {}, onGallery: {}, onDismiss: {})
}
