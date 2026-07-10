//
//  InfoTooltip.swift
//  BOAT
//
//  라벨/타이틀 옆에 붙는 "?" 아이콘. 탭하면 설명 말풍선(툴팁)이 아이콘 위에 뜬다.
//  시스템 alert 대신 사용 — 실물 영수증 보관 여부 / 시리얼 넘버 등 짧은 설명에 사용.
//

import SwiftUI

struct InfoTooltip: View {
    let message: LocalizedStringKey

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image("info_question_icon")
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundStyle(Color.gray400)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            Text(message)
                .font(.pretendard(.regular, size: 13))
                .foregroundStyle(Color.gray700)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.spacing12)
                .frame(maxWidth: 260)
                .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    InfoTooltip(message: "제조사 정책에 따라 수리 시 실물 영수증이 필요할 수 있으니, 확인 후 보관 여부를 선택해 주세요.")
        .padding(60)
}
