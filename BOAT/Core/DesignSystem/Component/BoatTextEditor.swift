//
//  BoatTextEditor.swift
//  BOAT
//
//  공통 멀티라인 입력 필드. 메모 같은 길이 제한 입력에 사용한다.
//

import SwiftUI
import UIKit

struct BoatTextEditor: View {

    @Binding var text: String
    var placeholder: LocalizedStringKey = ""
    var maxLength: Int? = nil
    var height: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.pretendard(.regular, size: 15))
                    .foregroundStyle(Color.gray400)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
            }

            LimitedTextView(
                text: $text,
                maxLength: maxLength
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(height: height)
        }
    }
}

private struct LimitedTextView: UIViewRepresentable {

    @Binding var text: String
    let maxLength: Int?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = UIColor(Color.gray900)
        textView.tintColor = UIColor(Color.brandPrimary)
        textView.font = .init(name: Font.Pretendard.regular.rawValue, size: 15)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.delegate = context.coordinator
        uiView.textColor = UIColor(Color.gray900)
        uiView.tintColor = UIColor(Color.brandPrimary)
        uiView.font = .init(name: Font.Pretendard.regular.rawValue, size: 15)

        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {

        private var parent: LimitedTextView

        init(_ parent: LimitedTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            guard let maxLength = parent.maxLength else {
                parent.text = textView.text
                return
            }

            let currentText = textView.text ?? ""
            if currentText.count <= maxLength {
                parent.text = currentText
                return
            }

            let limitedText = String(currentText.prefix(maxLength))
            textView.text = limitedText
            parent.text = limitedText
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            guard let currentText = textView.text,
                  let swiftRange = Range(range, in: currentText) else {
                return true
            }

            let proposedText = currentText.replacingCharacters(in: swiftRange, with: text)
            guard let maxLength = parent.maxLength, proposedText.count > maxLength else {
                parent.text = proposedText
                return true
            }

            let limitedText = String(proposedText.prefix(maxLength))
            textView.text = limitedText
            parent.text = limitedText
            textView.selectedRange = NSRange(location: limitedText.utf16.count, length: 0)
            return false
        }
    }
}
