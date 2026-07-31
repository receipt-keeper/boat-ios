//
//  BoatTextEditor.swift
//  BOAT
//
//  공통 멀티라인 입력 필드. 메모 같은 길이 제한 입력에 사용한다.
//
//  입력부는 SwiftUI 기본 TextEditor를 쓴다. 예전에는 UITextView를 UIViewRepresentable로
//  감싸 썼는데, BoatInputField와 같은 이유로 한글 조합(markedText)이 깨져 자모가 분리되는
//  문제가 있어 프레임워크가 조합을 직접 다루는 기본 컴포넌트로 대체했다.
//

import SwiftUI

struct BoatTextEditor: View {

    @Binding var text: String
    var placeholder: LocalizedStringKey = ""
    var maxLength: Int? = nil
    var height: CGFloat = 154

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                // Body2 Medium — Pretendard 500 / 14 / 행간 150%(21) / #757575
                Text(placeholder)
                    .font(.pretendard(.medium, size: 14))
                    .foregroundStyle(Color.gray600)
                    .lineSpacing(7)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.gray900)
                .tint(Color.brandPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                // TextEditor는 자체 내부 여백(약 5pt)이 있어, placeholder와 첫 글자가
                // 같은 위치에서 시작하도록 좌우를 그만큼 덜 준다.
                .padding(.horizontal, 7)
                .padding(.vertical, 9)
                .onChange(of: text) { _, newValue in
                    // 제한 초과분만 잘라낸다 — 평소 입력에서는 text를 다시 쓰지 않으므로
                    // 한글 조합에 영향을 주지 않는다.
                    if let maxLength, newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }
        }
        .frame(height: height)
    }
}
