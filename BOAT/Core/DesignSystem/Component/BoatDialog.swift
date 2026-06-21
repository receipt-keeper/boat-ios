//
//  BoatDialog.swift
//  BOAT
//
//  Android BoatDialog.kt 에 대응하는 커스텀 다이얼로그.
//  딤 배경 + 흰 카드, 제목(좌측 정렬) / 메시지 / 우측 하단 버튼.
//  시스템 Alert 대신 이 컴포넌트를 사용한다.
//

import SwiftUI

// MARK: - Card

private struct BoatDialogCard: View {
    let title: LocalizedStringKey?
    let message: LocalizedStringKey
    let confirmText: LocalizedStringKey
    let confirmColor: Color
    let cancelText: LocalizedStringKey?
    let cancelColor: Color
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.systemDim
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(alignment: .leading, spacing: 0) {
                if let title {
                    Text(title)
                        .font(.pretendard(.bold, size: 18))
                        .foregroundStyle(Color.gray900)
                    Spacer().frame(height: .spacing12)
                }

                Text(message)
                    .font(.pretendard(.regular, size: 15))
                    .foregroundStyle(Color.gray600)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer().frame(height: .spacing24)

                HStack(spacing: .spacing8) {
                    Spacer()
                    if let cancelText {
                        dialogButton(cancelText, color: cancelColor, action: onCancel)
                    }
                    dialogButton(confirmText, color: confirmColor, action: onConfirm)
                }
            }
            .padding(.spacing24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
            .padding(.horizontal, 40)
        }
    }

    private func dialogButton(
        _ text: LocalizedStringKey,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(text)
                .font(.pretendard(.medium, size: 15))
                .foregroundStyle(color)
                .padding(.horizontal, .spacing12)
                .padding(.vertical, .spacing8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modifier

private struct BoatDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: LocalizedStringKey?
    let message: LocalizedStringKey
    let confirmText: LocalizedStringKey
    let confirmColor: Color
    let cancelText: LocalizedStringKey?
    let cancelColor: Color
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                BoatDialogCard(
                    title: title,
                    message: message,
                    confirmText: confirmText,
                    confirmColor: confirmColor,
                    cancelText: cancelText,
                    cancelColor: cancelColor,
                    onConfirm: {
                        isPresented = false
                        onConfirm()
                    },
                    onCancel: { isPresented = false }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    /// 커스텀 다이얼로그 표시. 시스템 Alert 대신 사용한다.
    func boatDialog(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey? = nil,
        message: LocalizedStringKey,
        confirmText: LocalizedStringKey,
        confirmColor: Color = .brandPrimary,
        cancelText: LocalizedStringKey? = nil,
        cancelColor: Color = .gray600,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(BoatDialogModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            confirmText: confirmText,
            confirmColor: confirmColor,
            cancelText: cancelText,
            cancelColor: cancelColor,
            onConfirm: onConfirm
        ))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var show = true
        var body: some View {
            Color.gray100
                .ignoresSafeArea()
                .boatDialog(
                    isPresented: $show,
                    title: "dialog.logout.title",
                    message: "dialog.logout.message",
                    confirmText: "home.sign_out_button",
                    confirmColor: .brandPrimary,
                    cancelText: "common.cancel",
                    cancelColor: .brandPrimary,
                    onConfirm: {}
                )
        }
    }
    return PreviewWrapper()
}
