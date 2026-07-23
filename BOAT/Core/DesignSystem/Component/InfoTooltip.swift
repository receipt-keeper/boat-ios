//
//  InfoTooltip.swift
//  BOAT
//
//  라벨/타이틀 옆에 붙는 "?" 아이콘. 탭하면 설명 말풍선(툴팁)이 아이콘 위에 뜬다.
//  시스템 popover 대신 커스텀 말풍선(#E6EBF4 배경 + 하단 삼각 포인터)을 직접 그린다 —
//  디자인 가이드와 위치/모양을 100% 맞추기 위함 (Android InfoTooltip.kt 대응).
//

import SwiftUI

struct InfoTooltip: View {
    let message: LocalizedStringKey

    @State private var showTooltip = false

    private static let iconSize: CGFloat = 16
    private static let bubbleWidth: CGFloat = 160
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
        // alignment: .top의 기본 가로 중앙 정렬은 앵커(Button)의 "레이아웃상 실측 프레임" 기준이라
        // 탭 영역 등으로 프레임이 아이콘(16pt) 시각적 크기와 어긋나면 화살표가 아이콘 중앙에서 벗어난다.
        // → .topLeading + alignmentGuide로 아이콘의 실제 폭(iconSize) 기준 중앙을 직접 계산해 고정한다.
        .overlay(alignment: .topLeading) {
            if showTooltip {
                tooltipBubble
                    .alignmentGuide(.leading) { d in d.width / 2 - Self.iconSize / 2 }
                    // 앵커(?) 바로 위, gap만큼 띄워서 배치 — 말풍선 자체 높이와 무관하게 항상 위로 붙는다.
                    .alignmentGuide(.top) { d in d[.bottom] + Self.gap }
            }
        }
    }

    private var tooltipBubble: some View {
        VStack(spacing: -1) {
            Text(message)
                .font(.pretendard(.medium, size: 10))
                .foregroundStyle(Color.gray700)
                .multilineTextAlignment(.center)
                .lineSpacing(2.81)
                .frame(width: Self.bubbleWidth)
                .padding(.horizontal, .spacing12)
                .padding(.vertical, 10)
                .background(Color.brandQuinary, in: RoundedRectangle(cornerRadius: .roundedLg))
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)

            TooltipTriangle()
                .fill(Color.brandQuinary)
                .frame(width: Self.triangleSize.width, height: Self.triangleSize.height)
        }
        .onTapGesture { showTooltip = false }
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
    InfoTooltip(message: "제조사 정책에 따라 수리 시 실물 영수증이 필요할 수 있으니, 확인 후 보관 여부를 선택해 주세요.")
        .padding(60)
}
