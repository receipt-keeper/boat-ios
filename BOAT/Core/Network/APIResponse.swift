//
//  APIResponse.swift
//  BOAT
//
//  모든 API 응답이 공유하는 공통 Envelope 구조입니다.
//  서버는 성공/실패와 무관하게 동일한 껍데기를 내려주므로,
//  앱 단에서는 이 타입으로 한 번에 디코딩한 뒤 data만 꺼내 씁니다.
//
//  성공: { "success": true, "status": 0, "data": { ... } }
//  실패: { "success": ..., "status": ..., "data": { "message": "...", "errors": [...] } }
//

import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool?
    let status: Int?
    let data: T?
}

/// data 필드가 필요 없는(혹은 본문이 없는) 응답을 위한 빈 타입.
/// 예: 로그아웃, 삭제 등 본문 data 없이 내려오는 API.
struct EmptyData: Decodable {}

/// 실패 응답의 data 페이로드. 사용자 노출 문구는 message에서 꺼냅니다.
struct APIErrorData: Decodable {
    let timestamp: String?
    let message: String?
    let path: String?
    let errors: [FieldError]?

    struct FieldError: Decodable {
        let field: String?
        let message: String?
    }
}
