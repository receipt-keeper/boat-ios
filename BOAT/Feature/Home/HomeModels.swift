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
    let brand: String
    let purchaseDate: String
    /// "MM월 dd일(요일)" — "home.warranty_end"("%@ 보증종료")과 함께 쓴다.
    let expiryLabel: String
    let dDay: Int
    var localImageName: String? = nil
}

/// 최근 등록된 영수증 (홈 세로형 리스트)
struct RecentReceipt: Identifiable {
    let id: String
    let productName: String
    let purchaseDate: String
    let daysAgo: Int
    var localImageName: String? = nil
}

// MARK: - Receipt → 홈 화면 모델 매핑

extension Receipt {
    /// AS 만료 예정 가로형 카드용 매핑.
    func toExpiringWarranty() -> ExpiringWarranty {
        ExpiringWarranty(
            id: receiptId,
            productName: itemName,
            brand: Self.nonBlank(brandName) ?? "-",
            purchaseDate: Self.dotDate(paymentDate),
            expiryLabel: Self.expiryLabel(expiresOn),
            dDay: warrantyDDay ?? 0,
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

    /// "yyyy-MM-dd" → "MM월 dd일(요일)" (없거나 파싱 실패 시 "-")
    private static func expiryLabel(_ ymd: String?) -> String {
        guard let ymd, !ymd.isEmpty else { return "-" }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "ko_KR")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: ymd) else { return "-" }
        let out = DateFormatter()
        out.locale = Locale(identifier: "ko_KR")
        out.dateFormat = "MM월 dd일(E)"
        return out.string(from: date)
    }

    /// ISO8601 registeredAt → 경과일 (파싱 실패 시 0).
    /// Android(diffMs / 24h, 자정 기준 아님)와 동일하게 "경과 시간 ÷ 24시간" 방식으로 계산한다.
    /// Calendar.dateComponents(.day)를 쓰면 자정을 막 넘긴 경우 실제로는 몇 분밖에 안 지났어도
    /// "1일 전"으로 표시돼 Android와 어긋난다.
    private static func daysAgo(_ iso: String?) -> Int {
        guard let iso else { return 0 }
        var date = ISO8601DateFormatter().date(from: iso)
        if date == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            date = formatter.date(from: iso)
        }
        guard let date else { return 0 }
        let elapsedSeconds = Date().timeIntervalSince(date)
        let days = Int(elapsedSeconds / 86400)
        return max(0, days)
    }
}

// MARK: - 프리뷰용 샘플 데이터

enum HomeMock {
    static let expiringWarranties: [ExpiringWarranty] = [
        ExpiringWarranty(id: "1", productName: "MacBook Pro 16", brand: "Apple", purchaseDate: "2025.03.13", expiryLabel: "03월 23일(월)", dDay: 19, localImageName: "img_laptop"),
        ExpiringWarranty(id: "2", productName: "LG 그램 17", brand: "LG전자", purchaseDate: "2024.11.02", expiryLabel: "11월 01일(토)", dDay: 25, localImageName: "img_laptop"),
        ExpiringWarranty(id: "3", productName: "삼성 비스포크 냉장고", brand: "삼성전자", purchaseDate: "2023.07.21", expiryLabel: "07월 20일(일)", dDay: 28, localImageName: "img_refridgerator"),
    ]

    static let recentReceipts: [RecentReceipt] = [
        RecentReceipt(id: "1", productName: "IPad Pro 13", purchaseDate: "2027.12.03", daysAgo: 2),
        RecentReceipt(id: "2", productName: "IPad Pro 13", purchaseDate: "2027.12.03", daysAgo: 2),
    ]
}
