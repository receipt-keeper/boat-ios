//
//  Color+Foundation.swift
//  BOAT
//

import SwiftUI

// MARK: - Brand

extension Color {
    static let brandPrimary    = Color(hex: "#0088FF") // 메인 컬러 — 헤딩, 주요 아이콘, CTA
    static let brandSecondary  = Color(hex: "#0E70E3") // 서브 컬러 — 중요도 낮은 CTA
    static let brandTertiary   = Color(hex: "#C1DAFC") // 서브 컬러 — Border, 배너
    static let brandQuaternary = Color(hex: "#DAE6F7") // 서브 컬러 — Chip, 배너
    static let brandQuinary    = Color(hex: "#E6EBF4") // 서브 컬러 — Card Border, 배너
    static let brandSenary     = Color(hex: "#F0F8FF") // 서브 컬러 — 배너
}

// MARK: - System

extension Color {
    static let systemError   = Color(hex: "#FE395B") // 에러, 경고 메시지, 에러 아이콘
    static let systemSuccess = Color(hex: "#3694FF") // 완료, 성공 메시지, 성공 아이콘
    static let systemToast   = Color(hex: "#212121").opacity(0.8) // 토스트 배경 (텍스트: gray50)
    static let systemDim     = Color(hex: "#212121").opacity(0.5) // 모달 뒷화면 딤
}

// MARK: - System Badge

extension Color {
    // Safe (D-30 이상)
    static let badgeSafeBg     = Color(hex: "#E9F2FF")
    static let badgeSafeBorder = Color(hex: "#D2E4FF")
    static let badgeSafeText   = Color(hex: "#0E70E3")

    // Warning (D-30 미만)
    static let badgeWarningBg     = Color(hex: "#FFF1F1")
    static let badgeWarningBorder = Color(hex: "#FFC5C5")
    static let badgeWarningText   = Color(hex: "#FF3838")

    // Expired (만료)
    static let badgeExpiredBg     = Color(hex: "#EEEEEE")
    static let badgeExpiredBorder = Color(hex: "#E0E0E0")
    static let badgeExpiredText   = Color(hex: "#BDBDBD")
}

// MARK: - Grayscale

extension Color {
    static let colorWhite       = Color(hex: "#FFFFFF") // 카드, 모달, 섹션 배경 / White 서체
    static let gray10           = Color(hex: "#FDFEFF") // Sub background 1
    static let gray50           = Color(hex: "#F5F7FA") // Sub background 2
    static let gray100          = Color(hex: "#F5F5F5") // Sub background 3, 리스트, 작은 컨테이너 배경
    static let gray200          = Color(hex: "#EEEEEE") // Divider, subtle border
    static let gray300          = Color(hex: "#E0E0E0") // Divider, border, 카드 경계, Input Field, 버튼 테두리
    static let gray400          = Color(hex: "#BDBDBD") // 보조 아이콘, placeholder 텍스트
    static let gray500          = Color(hex: "#9E9E9E") // 보조 텍스트, 아이콘, placeholder
    static let gray600          = Color(hex: "#757575") // 본문 텍스트, 부가 아이콘, Divider
    static let gray700          = Color(hex: "#616161") // 서브 텍스트
    static let gray800          = Color(hex: "#212121") // 서브 텍스트
    static let gray900          = Color(hex: "#121212") // Heading, 메인 텍스트, 보조 아이콘
    static let gray900Opacity80 = Color(hex: "#121212").opacity(0.8) // 보조 아이콘, 시각적 구분
}

// MARK: - Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
