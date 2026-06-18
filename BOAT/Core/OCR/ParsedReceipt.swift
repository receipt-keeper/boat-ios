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

    // PRD 3-A 대표 기기명 리스트
    var keywords: [String] {
        switch self {
        case .kitchen:
            return ["냉장고", "전자레인지", "밥솥", "정수기", "식기세척기", "인덕션", "에어프라이어", "전기오븐", "블렌더", "토스터", "믹서기"]
        case .laundry:
            return ["세탁기", "건조기", "청소기", "로봇청소기", "스팀청소기", "의류관리기", "스타일러"]
        case .living:
            return ["에어컨", "선풍기", "공기청정기", "가습기", "제습기", "히터", "온풍기", "전기장판", "냉난방기"]
        case .it:
            return ["TV", "모니터", "노트북", "태블릿", "게임기", "카메라", "스피커", "PC", "컴퓨터", "프린터", "헤드폰", "이어폰", "스마트폰", "핸드폰"]
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
