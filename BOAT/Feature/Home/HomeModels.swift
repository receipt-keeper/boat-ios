//
//  HomeModels.swift
//  BOAT
//
//  홈 일반 화면 모델 + 임시(mock) 데이터. Android HomeModels 대응.
//

import Foundation

/// AS 만료 예정 기기 (홈 가로형 카드)
struct ExpiringWarranty: Identifiable {
    let id: Int
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
    let id: Int
    let productName: String
    let purchaseDate: String
    let daysAgo: Int
    var thumbnailUrl: String? = nil
}

// MARK: - 임시(mock) 데이터

enum HomeMock {
    /// AS 만료 예정 (만료 임박 오름차순)
    static let expiringWarranties: [ExpiringWarranty] = [
        ExpiringWarranty(id: 1, productName: "MacBook Pro 16", vendor: "Apple", purchaseDate: "2025.03.13", warrantyUntil: "~2033.04.40", dDay: 20, localImageName: "img_laptop"),
        ExpiringWarranty(id: 2, productName: "LG 그램 17", vendor: "LG전자", purchaseDate: "2024.11.02", warrantyUntil: "~2026.11.01", dDay: 25, localImageName: "img_laptop"),
        ExpiringWarranty(id: 3, productName: "삼성 비스포크 냉장고", vendor: "삼성전자", purchaseDate: "2023.07.21", warrantyUntil: "~2025.07.20", dDay: 28, localImageName: "img_refridgerator"),
    ]

    /// 최근 등록된 영수증 (최근순, 최대 5)
    static let recentReceipts: [RecentReceipt] = [
        RecentReceipt(id: 1, productName: "IPad Pro 13", purchaseDate: "2027. 12. 34", daysAgo: 2),
        RecentReceipt(id: 2, productName: "IPad Pro 13", purchaseDate: "2027. 12. 34", daysAgo: 2),
        RecentReceipt(id: 3, productName: "IPad Pro 13", purchaseDate: "2027. 12. 34", daysAgo: 2),
        RecentReceipt(id: 4, productName: "IPad Pro 13", purchaseDate: "2027. 12. 34", daysAgo: 2),
        RecentReceipt(id: 5, productName: "IPad Pro 13", purchaseDate: "2027. 12. 34", daysAgo: 2),
    ]
}
