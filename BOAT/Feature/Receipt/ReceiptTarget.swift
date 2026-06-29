//
//  ReceiptTarget.swift
//  BOAT
//
//  영수증 엔드포인트. GET /api/v1/receipts (상태/카테고리/검색/정렬 + 커서 페이지네이션)
//

import Foundation
import Alamofire

enum ReceiptTarget {
    /// GET /api/v1/receipts
    case list(
        status: String,
        sort: String,
        limit: Int,
        cursor: String?,
        category: String?,
        q: String?
    )
}

extension ReceiptTarget: TargetType {

    var path: String { "/api/v1/receipts" }

    var method: HTTPMethod { .get }

    var task: RequestTask {
        switch self {
        case let .list(status, sort, limit, cursor, category, q):
            var params: [String: Any] = [
                "status": status,
                "sort": sort,
                "limit": limit
            ]
            if let cursor, !cursor.isEmpty     { params["cursor"] = cursor }
            if let category, !category.isEmpty { params["category"] = category }
            if let q, !q.isEmpty               { params["q"] = q }
            return .query(params)
        }
    }
}

// MARK: - UI enum → API 쿼리 값 매핑

extension ReceiptTab {
    /// status 파라미터 값
    var apiStatus: String {
        switch self {
        case .all:      return "all"
        case .expiring: return "expiring"
        case .expired:  return "expired"
        }
    }
}

extension ReceiptSort {
    /// sort 파라미터 값
    var apiSort: String {
        switch self {
        case .default:  return "recent"        // 기본 순 = 등록일 내림차순
        case .recent:   return "recent"
        case .expiring: return "expiresOn"     // 만료 임박 순
        case .purchase: return "purchaseDate"  // 구매일 순
        }
    }
}

extension ReceiptFilter {
    /// category 파라미터 값 (완전 일치). 전체면 nil → 파라미터 미전송
    var apiCategory: String? {
        switch self {
        case .all:     return nil
        case .it:      return DeviceCategory.it.rawValue
        case .laundry: return DeviceCategory.laundry.rawValue
        case .kitchen: return DeviceCategory.kitchen.rawValue
        case .living:  return DeviceCategory.living.rawValue
        case .other:   return DeviceCategory.other.rawValue
        }
    }
}
