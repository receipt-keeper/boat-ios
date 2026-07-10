//
//  Skeleton.swift
//  BOAT
//
//  로딩 스켈레톤 플레이스홀더 — 좌→우로 스치는 셔머(shimmer) 애니메이션.
//  Android Skeleton.kt(rememberShimmerBrush + Modifier.shimmer) 대응.
//

import SwiftUI

private let shimmerBase = Color(hex: "#E9EEF6")      // 옅은 쿨블루그레이 (플레이스홀더 기본)
private let shimmerHighlight = Color(hex: "#F3F7FC") // 하이라이트(빛 스쳐가는 밴드)

/// 셔머 애니메이션이 적용된 스켈레톤 플레이스홀더 박스. 크기는 호출부에서 `.frame()`으로 지정.
struct ShimmerBox: View {
    var cornerRadius: CGFloat = .roundedMd

    @State private var animate = false

    var body: some View {
        shimmerBase
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [shimmerBase, shimmerHighlight, shimmerBase],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width)
                    .offset(x: animate ? geo.size.width : -geo.size.width)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}
