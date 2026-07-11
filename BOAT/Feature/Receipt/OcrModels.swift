//
//  OcrModels.swift
//  BOAT
//
//  영수증 OCR 분석(POST /api/v1/ocr) 응답 모델.
//  서버가 snake_case로 내려주므로 CodingKeys로 매핑한다.
//

import Foundation

/// OCR 분석 결과 페이로드 (응답 data).
struct OcrAnalysis: Decodable {
    let itemName: String?
    let brandName: String?
    let serialNumber: String?
    let paymentLocation: String?
    let paymentDate: String?        // "yyyy-MM-dd"
    let totalAmount: Int?
    let periodMonths: Int?
    let expiresOn: String?          // "yyyy-MM-dd"
    let category: String?
    let subCategory: String?
    let needsReview: Bool?
    let warnings: [String]?

    enum CodingKeys: String, CodingKey {
        case itemName        = "item_name"
        case brandName       = "brand_name"
        case serialNumber    = "serial_number"
        case paymentLocation = "payment_location"
        case paymentDate     = "payment_date"
        case totalAmount     = "total_amount"
        case periodMonths    = "period_months"
        case expiresOn       = "expires_on"
        case category
        case subCategory     = "sub_category"
        case needsReview     = "needs_review"
        case warnings
    }
}
