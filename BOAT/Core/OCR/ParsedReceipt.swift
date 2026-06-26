//
//  ParsedReceipt.swift
//  BOAT
//

import Foundation

enum DeviceCategory: String, CaseIterable {
    case kitchen = "주방 가전"
    case laundry = "세탁/청소"
    case living  = "리빙/냉난방"
    case it      = "IT 기기"
    case other   = "기타 기기"

    // 대표 기기명 리스트 (확정본). 리스트에 없는 기기명은 대분류 기본 이미지로 폴백.
    var keywords: [String] {
        switch self {
        case .kitchen:
            return ["냉장고", "전자레인지", "밥솥", "정수기"]
        case .laundry:
            return ["세탁기", "건조기", "청소기", "로봇청소기"]
        case .living:
            return ["에어컨", "선풍기", "공기청정기", "가습기"]
        case .it:
            return ["태블릿", "게임기", "카메라", "스피커", "무선 이어폰", "노트북", "헤드셋", "스마트워치", "핸드폰"]
        case .other:
            return []
        }
    }
}

struct ParsedReceipt {
    var productName: String?
    var purchaseDate: Date?
    var warrantyMonths: Int?
    var brandName: String?
    var price: Int?
    var serialNumber: String?
    var category: DeviceCategory

    // PRD 기본값 적용
    var resolvedPurchaseDate: Date { purchaseDate ?? Date() }
    var resolvedWarrantyMonths: Int { warrantyMonths ?? 12 }

    var warrantyExpiryDate: Date {
        Calendar.current.date(
            byAdding: .month,
            value: resolvedWarrantyMonths,
            to: resolvedPurchaseDate
        ) ?? resolvedPurchaseDate
    }
}
