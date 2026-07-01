//
//  ReceiptEntity.swift
//  BOAT
//
//  영수증 로컬 캐시(SwiftData) 엔티티. 오프라인에서도 등록한 영수증을 볼 수 있도록
//  서버 응답(Receipt)을 그대로 로컬에 저장한다. Android ReceiptEntity 대응.
//

import Foundation
import SwiftData

@Model
final class ReceiptEntity {
    @Attribute(.unique) var receiptId: String
    var itemName: String
    var brandName: String?
    var paymentLocation: String?
    var paymentDate: String?
    var totalAmount: Int?
    var periodMonths: Int?
    var expiresOn: String?
    var category: String?
    var subCategory: String?
    var memo: String?
    var requiresPhysicalReceipt: Bool
    var receiptFileIds: [String]
    var imageUrl: String?
    var warrantyDDay: Int?
    var serialNumber: String?
    var supportUrl: String?
    var registeredAt: String?
    /// 로컬 정렬/최근 등록 판별용 저장 시각 (서버 registeredAt 누락 대비)
    var cachedAt: Date

    init(from r: Receipt, cachedAt: Date = Date()) {
        self.receiptId = r.receiptId
        self.itemName = r.itemName
        self.brandName = r.brandName
        self.paymentLocation = r.paymentLocation
        self.paymentDate = r.paymentDate
        self.totalAmount = r.totalAmount
        self.periodMonths = r.periodMonths
        self.expiresOn = r.expiresOn
        self.category = r.category
        self.subCategory = r.subCategory
        self.memo = r.memo
        self.requiresPhysicalReceipt = r.requiresPhysicalReceipt ?? false
        self.receiptFileIds = r.receiptFileIds ?? []
        self.imageUrl = r.imageUrl
        self.warrantyDDay = r.warrantyDDay
        self.serialNumber = r.serialNumber
        self.supportUrl = r.supportUrl
        self.registeredAt = r.registeredAt
        self.cachedAt = cachedAt
    }

    /// 서버 응답 값으로 기존 레코드 갱신 (upsert 시 재사용)
    func update(from r: Receipt, cachedAt: Date = Date()) {
        itemName = r.itemName
        brandName = r.brandName
        paymentLocation = r.paymentLocation
        paymentDate = r.paymentDate
        totalAmount = r.totalAmount
        periodMonths = r.periodMonths
        expiresOn = r.expiresOn
        category = r.category
        subCategory = r.subCategory
        memo = r.memo
        requiresPhysicalReceipt = r.requiresPhysicalReceipt ?? false
        receiptFileIds = r.receiptFileIds ?? []
        imageUrl = r.imageUrl
        warrantyDDay = r.warrantyDDay
        serialNumber = r.serialNumber
        supportUrl = r.supportUrl
        registeredAt = r.registeredAt
        self.cachedAt = cachedAt
    }

    /// 로컬 엔티티 → 화면 모델(Receipt)
    func toReceipt() -> Receipt {
        Receipt(
            receiptId: receiptId,
            itemName: itemName,
            brandName: brandName,
            paymentLocation: paymentLocation,
            paymentDate: paymentDate,
            totalAmount: totalAmount,
            periodMonths: periodMonths,
            expiresOn: expiresOn,
            category: category,
            subCategory: subCategory,
            memo: memo,
            requiresPhysicalReceipt: requiresPhysicalReceipt,
            receiptFileIds: receiptFileIds,
            imageUrl: imageUrl,
            warrantyDDay: warrantyDDay,
            serialNumber: serialNumber,
            supportUrl: supportUrl,
            registeredAt: registeredAt
        )
    }
}
