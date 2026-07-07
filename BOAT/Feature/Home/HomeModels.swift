//
//  HomeModels.swift
//  BOAT
//
//  홈 일반 화면 모델 + Receipt → 화면 모델 매핑. Android HomeModels 대응.
//

import Foundation

/// AS 만료 예정 기기 (홈 가로형 카드)
struct ExpiringWarranty: Identifiable {
    let id: String
    let productName: String
    let vendor: String
    let purchaseDate: String
    let warrantyUntil: String
    let dDay: Int
    var thumbnailUrl: String? = nil
    var localImageName: String? = nil
}

/// 최근 등록된 영수증 (홈 세로형 리스트)
struct RecentReceipt: Identifiable {
    let id: String
    let productName: String
    let purchaseDate: String
    let daysAgo: Int
    var thumbnailUrl: String? = nil
    var localImageName: String? = nil
}

// MARK: - Receipt → 홈 화면 모델 매핑

extension Receipt {
    /// AS 만료 예정 가로형 카드용 매핑.
    func toExpiringWarranty() -> ExpiringWarranty {
        ExpiringWarranty(
            id: receiptId,
            productName: itemName,
            vendor: Self.nonBlank(brandName) ?? "-",
            purchaseDate: Self.dotDate(paymentDate),
            warrantyUntil: "~" + Self.dotDate(expiresOn),
            dDay: warrantyDDay ?? 0,
            thumbnailUrl: imageUrl,
            localImageName: deviceImageName
        )
    }

    /// 최근 등록된 영수증 세로형 리스트용 매핑.
    func toRecentReceipt() -> RecentReceipt {
        RecentReceipt(
            id: receiptId,
            productName: itemName,
            purchaseDate: Self.dotDate(paymentDate),
            daysAgo: Self.daysAgo(registeredAt),
            thumbnailUrl: imageUrl,
            localImageName: deviceImageName
        )
    }

    private static func nonBlank(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }

    /// "yyyy-MM-dd" → "yyyy.MM.dd" (없으면 "-")
    private static func dotDate(_ ymd: String?) -> String {
        guard let ymd, !ymd.isEmpty else { return "-" }
        return ymd.replacingOccurrences(of: "-", with: ".")
    }

    /// ISO8601 registeredAt → 오늘까지 경과일 (파싱 실패 시 0)
    private static func daysAgo(_ iso: String?) -> Int {
        guard let iso else { return 0 }
        var date = ISO8601DateFormatter().date(from: iso)
        if date == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            date = formatter.date(from: iso)
        }
        guard let date else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return max(0, days)
    }
}

// MARK: - 프리뷰용 샘플 데이터

enum HomeMock {
    static let expiringWarranties: [ExpiringWarranty] = [
        ExpiringWarranty(id: "1", productName: "MacBook Pro 16", vendor: "Apple", purchaseDate: "2025.03.13", warrantyUntil: "~2033.04.40", dDay: 20, localImageName: "img_laptop"),
        ExpiringWarranty(id: "2", productName: "LG 그램 17", vendor: "LG전자", purchaseDate: "2024.11.02", warrantyUntil: "~2026.11.01", dDay: 25, localImageName: "img_laptop"),
        ExpiringWarranty(id: "3", productName: "삼성 비스포크 냉장고", vendor: "삼성전자", purchaseDate: "2023.07.21", warrantyUntil: "~2025.07.20", dDay: 28, localImageName: "img_refridgerator"),
    ]

    static let recentReceipts: [RecentReceipt] = [
        RecentReceipt(id: "1", productName: "IPad Pro 13", purchaseDate: "2027.12.03", daysAgo: 2),
        RecentReceipt(id: "2", productName: "IPad Pro 13", purchaseDate: "2027.12.03", daysAgo: 2),
    ]
}
