//
//  APIResponse.swift
//  BOAT
//
//  모든 API 응답이 공유하는 공통 Envelope 구조입니다.
//  서버는 성공/실패와 무관하게 동일한 껍데기를 내려주므로,
//  앱 단에서는 이 타입으로 한 번에 디코딩한 뒤 data만 꺼내 씁니다.
//
//  {
//    "message": "성공했습니다.",   // 사용자에게 노출할 완성된 문구
//    "data": { ... }              // 실제 비즈니스 데이터 (에러 시 없을 수 있음)
//  }
//

import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let message: String
    let data: T?
}

/// data 필드가 필요 없는(혹은 본문이 없는) 응답을 위한 빈 타입.
/// 예: 로그아웃, 삭제 등 message만 내려오는 API.
struct EmptyData: Decodable {}
