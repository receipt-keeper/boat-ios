//
//  InfoTooltip.swift
//  BOAT
//
//  라벨/타이틀 옆에 붙는 "?" 아이콘. 탭하면 설명 말풍선(툴팁)이 아이콘 "위"에 뜬다.
//  시스템 popover 대신 커스텀 말풍선(Brand/Quinary 배경 + 하단 삼각 포인터)을 직접 그린다 —
//  디자인 가이드와 위치/모양을 100% 맞추기 위함 (Android InfoTooltip.kt 대응).
//
//  구현: 아이콘 버튼에 .overlay(alignment: .top)로 말풍선을 얹는다.
//  - 가로: .overlay(alignment: .top)이 말풍선을 아이콘 가로 중앙에 정렬하고, 삼각 포인터는
//    말풍선(VStack) 가로 중앙에 있으므로 → 삼각형이 항상 아이콘 정중앙을 가리킨다.
//  - 세로: .overlay(alignment: .top)은 기본적으로 말풍선 top을 아이콘 top에 붙여 "아래로" 펼치므로
//    아이콘을 덮는다. 이를 막기 위해 말풍선 실제 높이를 미리 측정(hidden 복제)해 두고,
//    표시되는 말풍선을 (높이 + gap)만큼 위로 offset → 말풍선이 아이콘 위에, gap을 두고 뜬다.
//    (alignmentGuide(.top) 트릭은 환경에 따라 적용이 불안정해 명시적 offset 방식으로 대체.)
//

import SwiftUI

struct InfoTooltip: View {
    let message: LocalizedStringKey

    @State private var showTooltip = false
    @State private var bubbleHeight: CGFloat = 0

    private static let iconSize: CGFloat = 16
    private static let textWidth: CGFloat = 160
    private static let triangleSize = CGSize(width: 14, height: 7)
    private static let gap: CGFloat = 6

    var body: some View {
        Button {
            showTooltip.toggle()
        } label: {
            Image("info_question_icon")
                .renderingMode(.template)
                .resizable()
                .frame(width: Self.iconSize, height: Self.iconSize)
                .foregroundStyle(Color.gray400)
        }
        .buttonStyle(.plain)
        // 말풍선 높이를 항상 미리 측정 — 표시되는 첫 프레임부터 정확히 아이콘 "위"에 배치되도록.
        .background(alignment: .top) {
            bubbleContent
                .fixedSize()
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { bubbleHeight = geo.size.height }
                            .onChange(of: geo.size.height) { _, newValue in bubbleHeight = newValue }
                    }
                )
                .hidden()
        }
        .overlay(alignment: .top) {
            if showTooltip {
                bubbleContent
                    .fixedSize()
                    // 말풍선 top이 아이콘 top에 붙는 기본 배치에서, 자기 높이+gap만큼 위로 올려
                    // 말풍선 전체가 아이콘 위에 gap을 두고 뜨게 한다.
                    .offset(y: -(bubbleHeight + Self.gap))
                    .onTapGesture { showTooltip = false }
            }
        }
    }

    private var bubbleContent: some View {
        VStack(spacing: -1) {
            Text(message)
                .font(.pretendard(.medium, size: 10))
                .foregroundStyle(Color.gray700)
                .multilineTextAlignment(.center)
                .lineSpacing(2.81)
                .frame(width: Self.textWidth)
                .padding(.horizontal, .spacing12)
                .padding(.vertical, 10)
                .background(Color.brandQuinary, in: RoundedRectangle(cornerRadius: .roundedLg))
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)

            TooltipTriangle()
                .fill(Color.brandQuinary)
                .frame(width: Self.triangleSize.width, height: Self.triangleSize.height)
        }
    }
}

/// 말풍선 하단 포인터 — 위쪽 변 전체에서 아래 중앙 꼭짓점으로 모이는 삼각형(Android Canvas Path 대응).
private struct TooltipTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack {
        HStack {
            Text("시리얼 넘버")
            InfoTooltip(message: "제품에 따라 일련번호는 '시리얼 번호', '제조번호' 등 다양한 이름으로 표기될 수 있습니다.")
        }
    }
    .padding(60)
}
