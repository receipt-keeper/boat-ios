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
    /// GET /api/v1/receipts/{receipt_id} — 영수증 상세 조회
    case detail(receiptId: String)
    /// PATCH /api/v1/receipts/{receipt_id} — 영수증 수정
    case update(receiptId: String, body: [String: Any])
}

extension ReceiptTarget: TargetType {

    var path: String {
        switch self {
        case .list, .create:
            return "/api/v1/receipts"
        case let .delete(receiptId):
            return "/api/v1/receipts/\(receiptId)"
        case let .detail(receiptId):
            return "/api/v1/receipts/\(receiptId)"
        case let .update(receiptId, _):
            return "/api/v1/receipts/\(receiptId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .detail: return .get
        case .create:        return .post
        case .delete:        return .delete
        case .update:        return .patch
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

        case let .update(_, body):
            return .body(body)

        case .delete, .detail:
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
    /// 클라이언트 필터 매칭용 대상 문자열. 반드시 DeviceCategory.rawValue와 같아야 한다 —
    /// 영수증 생성/수정 시 앱이 실제로 저장하는 category 값이 rawValue이기 때문이다
    /// (ReceiptManualInputView/ReceiptEditView 참고). 예전엔 이 값이 별도로 하드코딩되어 있었는데,
    /// .it("영상/IT 제품")과 .other("기타")가 실제 저장값("IT 기기"/"기타 기기")과 달라
    /// normalizeCategory로 정규화해도 매칭이 실패해 해당 두 카테고리 필터가 아무 것도
    /// 걸러내지 못하는 버그가 있었다. rawValue를 그대로 참조해 재발을 막는다.
    /// 전체면 nil → 파라미터 미전송.
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
