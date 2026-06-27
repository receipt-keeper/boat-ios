//
//  BoatInputField.swift
//  BOAT
//
//  공통 입력 필드. Android BoatInputField 대응.
//  스펙: height 52 / radius 8(roundedLg) / width는 컨테이너 채움.
//  라벨(+필수) / placeholder / 상태: 기본(gray300) · 포커스(brandPrimary) · 에러(systemError + 헬퍼) · 비활성(gray200)
//

import SwiftUI

struct BoatInputField: View {

    @Binding var text: String
    var label: LocalizedStringKey? = nil
    var required: Bool = false
    var placeholder: LocalizedStringKey = ""
    var isError: Bool = false
    var errorText: LocalizedStringKey? = nil
    var enabled: Bool = true
    var keyboard: UIKeyboardType = .default

    @FocusState private var focused: Bool

    private var borderColor: Color {
        if isError { return .systemError }
        if !enabled { return .gray200 }
        return focused ? .brandPrimary : .gray300
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label {
                HStack(spacing: 0) {
                    Text(label)
                        .font(.pretendard(.medium, size: 14))
                        .foregroundStyle(Color.gray600)
                    if required {
                        Text(" *")
                            .font(.pretendard(.medium, size: 14))
                            .foregroundStyle(Color.systemError)
                    }
                }
                Spacer().frame(height: .spacing8)
            }

            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.gray400))
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.gray900)
                .keyboardType(keyboard)
                .focused($focused)
                .disabled(!enabled)
                .padding(.horizontal, .spacing16)
                .frame(height: 52)
                .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
                .overlay(
                    RoundedRectangle(cornerRadius: .roundedLg)
                        .stroke(borderColor, lineWidth: 1)
                )

            if isError, let errorText {
                Spacer().frame(height: 6)
                Text(errorText)
                    .font(.pretendard(.medium, size: 13))
                    .foregroundStyle(Color.systemError)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BoatInputField(text: .constant(""), label: "label", placeholder: "내용을 입력하세요.")
        BoatInputField(text: .constant("내용을 입력하세요."), label: "label")
        BoatInputField(text: .constant("내용을 입력하세요."), label: "label", isError: true, errorText: "최대 30자까지 입력할 수 있습니다.")
    }
    .padding()
}
