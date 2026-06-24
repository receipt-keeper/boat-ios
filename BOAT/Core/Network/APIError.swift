//
//  APIError.swift
//  BOAT
//
//  네트워크 계층 공통 에러. Android ApiErrorParser 규칙에 맞춤:
//  - 5xx(서버 오류) 또는 네트워크 연결 실패 → network 문구
//  - 그 외(4xx 등) → 서버 응답 본문의 data.message
//  - 메시지 파싱 불가 → 일반 오류 문구
//

import Foundation

enum APIError: LocalizedError {
    /// 4xx — 서버가 준 사용자 노출 문구(data.message)
    case server(statusCode: Int, message: String)
    /// 5xx 또는 네트워크 연결 실패
    case network
    /// 파싱 불가 등 그 외
    case unknown

    var errorDescription: String? {
        switch self {
        case .server(_, let message):
            return message
        case .network:
            return String(localized: "error.api.network")
        case .unknown:
            return String(localized: "error.api.unknown")
        }
    }
}
