//
//  APIError.swift
//  BOAT
//
//  네트워크 계층에서 발생할 수 있는 에러를 통합 정의합니다.
//  ViewModel은 이 타입만 알면 되며, 사용자에게 보여줄 메시지는
//  errorDescription으로 일관되게 꺼내 씁니다.
//

import Foundation

enum APIError: LocalizedError {
    /// 요청 URL 구성 실패
    case invalidURL
    /// 서버 응답이 비었거나 형식이 잘못됨
    case emptyResponse
    /// 응답 디코딩 실패 (모델 불일치 등)
    case decodingFailed
    /// 서버가 내려준 에러 (HTTP 4xx/5xx). message는 서버가 준 사용자 노출 문구.
    case server(statusCode: Int, message: String)
    /// 네트워크 연결 실패 등 그 외 전송 에러
    case transport(Error)
    /// 알 수 없는 에러
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "error.api.invalid_url")
        case .emptyResponse:
            return String(localized: "error.api.empty_response")
        case .decodingFailed:
            return String(localized: "error.api.decode_failed")
        case .server(_, let message):
            return message
        case .transport:
            return String(localized: "error.api.network")
        case .unknown:
            return String(localized: "error.api.unknown")
        }
    }
}
