//
//  Font+Foundation.swift
//  BOAT
//
//  Android Typography(Type.kt)에 대응하는 폰트 토큰.
//  앱 기본 폰트는 Pretendard. 필요한 스타일을 추가로 확장하세요.
//

import SwiftUI

extension Font {

    /// Pretendard 굵기별 PostScript 이름
    enum Pretendard: String {
        case regular  = "Pretendard-Regular"
        case medium   = "Pretendard-Medium"
        case semibold = "Pretendard-SemiBold"
        case bold     = "Pretendard-Bold"
    }

    /// Pretendard 폰트 생성 헬퍼
    static func pretendard(_ weight: Pretendard, size: CGFloat) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

// MARK: - Typography Tokens (Android bodyMedium 등 대응)

extension Font {
    /// body2 — Pretendard Regular 14pt (lineHeight 20)
    static let body2 = pretendard(.regular, size: 14)
    /// body2 medium — Pretendard Medium 14pt (Toast 메시지 등)
    static let body2Medium = pretendard(.medium, size: 14)
}
