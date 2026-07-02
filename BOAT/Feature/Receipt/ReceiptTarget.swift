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
    /// POST /api/v1/receipts — OCR 결과 수정본/수동 입력값으로 영수증 등록
    case create(body: [String: Any])
    /// DELETE /api/v1/receipts/{receipt_id} — 영수증 삭제
    case delete(receiptId: String)
}

extension ReceiptTarget: TargetType {

    var path: String {
        switch self {
        case .list, .create:
            return "/api/v1/receipts"
        case let .delete(receiptId):
            return "/api/v1/receipts/\(receiptId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list:   return .get
        case .create: return .post
        case .delete: return .delete
        }
    }

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

        case let .create(body):
            return .body(body)

        case .delete:
            return .plain
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
    /// category 파라미터 값 (서버 필터 계약). 전체면 nil → 파라미터 미전송.
    /// Android ReceiptListViewModel.toApiCategory()와 동일한 문자열 사용.
    var apiCategory: String? {
        switch self {
        case .all:     return nil
        case .it:      return "영상/IT 제품"
        case .laundry: return "세탁/청소"
        case .kitchen: return "주방가전"
        case .living:  return "리빙/냉난방"
        case .other:   return "기타"
        }
    }
}
