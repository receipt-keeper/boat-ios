//
//  ParsedReceipt.swift
//  BOAT
//

import Foundation

enum DeviceCategory: String, CaseIterable, Codable {
    case kitchen = "주방 가전"
    case laundry = "세탁/청소"
    case living  = "리빙/냉난방"
    case it      = "IT 기기"
    case other   = "기타 기기"

    /// 대분류(기본) 이미지 에셋. 소분류 매칭 실패 시 폴백.
    var imageName: String {
        switch self {
        case .kitchen: return "img_kitchen"
        case .laundry: return "img_laundry_room"
        case .living:  return "img_living_room"
        case .it:      return "img_digital_device"
        case .other:   return "img_misc"
        }
    }

    /// 대표 기기명(소분류) → 전용 이미지 에셋. 디자인 가이드 확정본의 각 대분류별 대표 기기.
    /// (별칭/변형 흡수는 DeviceImage에서 처리 — 여기는 UI 노출용 대표명만 유지)
    var subcategoryImages: [String: String] {
        switch self {
        case .kitchen:
            return [
                "냉장고":      "img_refridgerator",
                "전자레인지":   "img_microwave",
                "밥솥":        "img_rice_cooker",
                "정수기":      "img_water_purifier",
                "오븐":        "img_oven",
            ]
        case .laundry:
            return [
                "세탁기":      "img_washing_machine",
                "청소기":      "img_vacuum_cleaner",
                "건조기":      "img_dry_machine",
                "로봇청소기":   "img_robot_vacuum",
            ]
        case .living:
            return [
                "에어컨":      "img_air_conditioner",
                "선풍기":      "img_fan",
                "공기청정기":   "img_air_purifier",
                "가습기":      "img_humidifier",
            ]
        case .it:
            return [
                "데스크탑/TV":  "img_monitor",
                "스피커":      "img_speaker",
                "카메라":      "img_camera",
                "게임기":      "img_game_console",
                "헤드셋":      "img_headset",
                "스마트워치":   "img_smartwatch",
                "핸드폰":      "img_smartphone",
                "무선이어폰":   "img_bluetooth_earphone",
                "노트북":      "img_laptop",
            ]
        case .other:
            return [:]
        }
    }

    /// 대표 기기명 리스트 (확정본). 리스트에 없는 기기명은 대분류 기본 이미지로 폴백.
    var keywords: [String] { Array(subcategoryImages.keys) }

    /// 서버 category 문자열 → enum. 공백 편차 + 라벨 변형(영상/IT 제품 등)을 흡수. Android DeviceImage.categoryDefault 대응.
    static func from(serverValue: String?) -> DeviceCategory? {
        let key = normalizeCategory(serverValue)
        guard !key.isEmpty else { return nil }
        switch key {
        case "주방가전":                                    return .kitchen
        case "세탁/청소", "세탁청소":                        return .laundry
        case "리빙/냉난방", "리빙냉난방":                    return .living
        case "it제품", "it기기", "영상/it제품", "영상it제품": return .it
        case "기타", "기타제품", "기타기기":                 return .other
        default:                                           return nil
        }
    }

    /// 공백 제거 + 소문자화 (슬래시는 카테고리 구분자로 유지)
    static func normalizeCategory(_ raw: String?) -> String {
        (raw ?? "").trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }
}

// MARK: - 기기 이미지 매핑 (category + subCategory → 에셋)

/// 서버가 내려주는 category(대분류)/subCategory(소분류=대표 기기명) 문자열을 이미지 에셋 이름으로 변환한다.
/// 우선순위: 소분류 전용 이미지 → 대분류 기본 이미지 → 공통(img_misc). Android core/ocr/DeviceImage.kt와 동일한 매핑.
enum DeviceImage {

    /// 소분류(대표 기기명) → 에셋. 대표명(각 카테고리) + 서버 표기 변형/별칭까지 포함해 전역 조회. 키는 normalize된 형태.
    private static let subcategoryImages: [String: String] = {
        var map: [String: String] = [:]
        // 1) 각 대분류의 대표 기기명
        for category in DeviceCategory.allCases {
            for (name, asset) in category.subcategoryImages {
                map[DeviceCategory.normalizeCategory(name)] = asset
            }
        }
        // 2) 서버 표기 변형/별칭 (Android SUB_CATEGORY_IMAGE 대응)
        let aliases: [String: String] = [
            "데스크탑": "img_monitor",
            "tv":      "img_monitor",
            "티비":     "img_monitor",
            "모니터":   "img_monitor",
            "휴대폰":   "img_smartphone",
            "스마트폰":  "img_smartphone",
            "이어폰":   "img_bluetooth_earphone",
        ]
        for (name, asset) in aliases {
            map[DeviceCategory.normalizeCategory(name)] = asset
        }
        return map
    }()

    /// category + subCategory로 최종 표시 이미지 결정. 소분류 우선, 없으면 대분류 기본.
    static func assetName(category: String?, subCategory: String?) -> String {
        if let asset = subcategoryImages[DeviceCategory.normalizeCategory(subCategory)] {
            return asset
        }
        return DeviceCategory.from(serverValue: category)?.imageName ?? DeviceCategory.other.imageName
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
