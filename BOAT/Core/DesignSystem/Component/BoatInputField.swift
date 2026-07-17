//
//  BoatInputField.swift
//  BOAT
//
//  공통 입력 필드. Android BoatInputField 대응.
//  스펙: height 52 / radius 8(roundedLg) / width는 컨테이너 채움.
//  라벨(+필수) / placeholder / 상태: 기본(gray300) · 포커스(brandPrimary) · 에러(systemError + 헬퍼) · 비활성(gray200)
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

    @State private var focused = false

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

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.pretendard(.regular, size: 15))
                        .foregroundStyle(Color.gray400)
                        .padding(.horizontal, .spacing16)
                }

                LimitedTextField(
                    text: $text,
                    keyboardType: keyboard,
                    maxLength: maxLength,
                    isEnabled: enabled,
                    isEditing: $focused
                )
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
}

private struct LimitedTextField: UIViewRepresentable {

    @Binding var text: String
    let keyboardType: UIKeyboardType
    let maxLength: Int?
    let isEnabled: Bool
    @Binding var isEditing: Bool

    func makeUIView(context: Context) -> PaddedTextField {
        let textField = PaddedTextField()
        textField.delegate = context.coordinator
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.textColor = UIColor(Color.gray900)
        textField.tintColor = UIColor(Color.brandPrimary)
        textField.font = .init(name: Font.Pretendard.regular.rawValue, size: 15)
        textField.keyboardType = keyboardType
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .never
        textField.leftPadding = .spacing16
        textField.rightPadding = .spacing16
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateUIView(_ uiView: PaddedTextField, context: Context) {
        uiView.delegate = context.coordinator
        uiView.isEnabled = isEnabled
        uiView.keyboardType = keyboardType
        uiView.textColor = UIColor(Color.gray900)
        uiView.tintColor = UIColor(Color.brandPrimary)
        uiView.font = .init(name: Font.Pretendard.regular.rawValue, size: 15)

        // 편집 중(첫 응답자)일 땐 uiView.text를 다시 덮어쓰지 않는다. 한글처럼 여러 keystroke가
        // 빠르게 이어지는 IME 입력 중에 델리게이트→Binding→SwiftUI 재렌더 왕복이 한 박자 늦게
        // 돌아오면, 여기서 최신 입력을 아직 반영 못한 stale text로 되돌려써서 글자가 중복/유실
        // 되는 문제가 있었다. 편집 중이 아닐 때만(프로그램적 초기화 등) 동기화한다.
        if !uiView.isFirstResponder, uiView.text != text {
            uiView.text = text
        }

        if isEditing, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isEditing, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {

        private var parent: LimitedTextField

        init(_ parent: LimitedTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isEditing = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isEditing = false
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            guard let currentText = textField.text,
                  let swiftRange = Range(range, in: currentText) else {
                return true
            }

            let proposedText = currentText.replacingCharacters(in: swiftRange, with: string)
            guard let maxLength = parent.maxLength, proposedText.count > maxLength else {
                parent.text = proposedText
                return true
            }

            let limitedText = String(proposedText.prefix(maxLength))
            textField.text = limitedText
            parent.text = limitedText
            return false
        }
    }
}

private final class PaddedTextField: UITextField {

    var leftPadding: CGFloat = 0
    var rightPadding: CGFloat = 0

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding))
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding))
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding))
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
