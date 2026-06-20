//
//  Spacing+Foundation.swift
//  BOAT
//

import CoreFoundation

// MARK: - Spacing (Margin / Padding 공통 규칙)
// 16pt 이하: 4의 배수 / 16pt 초과: 8의 배수

extension CGFloat {
    static let spacing4:  CGFloat = 4
    static let spacing8:  CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing40: CGFloat = 40
    static let spacing48: CGFloat = 48
    static let spacing56: CGFloat = 56
    static let spacing64: CGFloat = 64
}

// MARK: - Radius

extension CGFloat {
    static let roundedSm:   CGFloat = 4
    static let roundedMd:   CGFloat = 6
    static let roundedLg:   CGFloat = 8
    static let roundedXl:   CGFloat = 12
    static let rounded2xl:  CGFloat = 16
    static let rounded3xl:  CGFloat = 24
    static let roundedFull: CGFloat = 9999
}
