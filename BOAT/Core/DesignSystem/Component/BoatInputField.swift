//
//  BoatInputField.swift
//  BOAT
//
//  공통 입력 필드. Android BoatInputField 대응.
//  스펙: height 52 / radius 8(roundedLg) / width는 컨테이너 채움.
//  라벨(+필수) / placeholder / 상태: 기본(gray300) · 포커스(brandPrimary) · 에러(systemError + 헬퍼) · 비활성(gray200)
//
//  입력부는 SwiftUI 기본 TextField를 쓴다.
//  예전에는 UITextField를 UIViewRepresentable로 감싸 썼는데, 키 입력마다 바인딩이 갱신되며
//  SwiftUI 업데이트가 돌고 그 과정에서 시스템이 들고 있던 한글 조합(markedText) 상태가 깨져
//  "하트"가 "핱ㅡ"처럼 자모가 분리되는 문제가 있었다. 조합 중 UITextField의 text/속성을
//  건드리지 않도록 가드를 넣어도 완전히 막히지 않아, 조합을 프레임워크가 직접 다루는
//  기본 TextField로 대체했다. (숫자/글자수 제한은 아래 onChange에서 처리)
//

import SwiftUI
import UIKit

struct BoatInputField: View {

    @Binding var text: String
    var label: LocalizedStringKey? = nil
    var required: Bool = false
    var placeholder: LocalizedStringKey = ""
    var isError: Bool = false
    var errorText: LocalizedStringKey? = nil
    var enabled: Bool = true
    var keyboard: UIKeyboardType = .default
    var maxLength: Int? = nil
    /// 숫자 자릿수 제한(가격 필드처럼 콤마가 섞이는 값). 서식 문자는 세지 않는다.
    var maxDigits: Int? = nil

    @FocusState private var isFocused: Bool

    private var borderColor: Color {
        if isError { return .systemError }
        if !enabled { return .gray200 }
        return isFocused ? .brandPrimary : .gray300
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

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.pretendard(.medium, size: 16))
                        .foregroundStyle(Color.gray400)
                        .padding(.horizontal, .spacing16)
                        .allowsHitTesting(false)
                }

                TextField("", text: $text)
                    .font(.pretendard(.medium, size: 16))
                    .foregroundStyle(Color.gray900)
                    .tint(Color.brandPrimary)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(!enabled)
                    .focused($isFocused)
                    .padding(.horizontal, .spacing16)
                    .onChange(of: text) { _, newValue in enforceLimits(newValue) }
            }
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

    /// 제한 초과분만 잘라낸다. 제한에 걸리지 않는 평소 입력에서는 text를 다시 쓰지 않으므로
    /// 한글 조합에 영향을 주지 않는다.
    private func enforceLimits(_ newValue: String) {
        if let maxDigits, newValue.filter(\.isNumber).count > maxDigits {
            text = String(newValue.filter(\.isNumber).prefix(maxDigits))
            return
        }
        if let maxLength, newValue.count > maxLength {
            text = String(newValue.prefix(maxLength))
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
