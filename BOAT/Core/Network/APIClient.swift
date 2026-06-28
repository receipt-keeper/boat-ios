//
//  APIClient.swift
//  BOAT
//
//  TargetType으로 정의한 엔드포인트를 실제로 호출하고,
//  공통 Envelope(APIResponse)을 벗겨 비즈니스 데이터(data)만 반환합니다.
//
//  사용 예:
//  let user: User = try await APIClient.shared.request(AuthTarget.login(idToken: token))
//
//  - 성공: APIResponse.data를 디코딩해 그대로 반환
//  - 실패(4xx/5xx): 서버가 준 message를 담아 APIError.server를 throw
//
//  ※ JWT 토큰 자동 주입/갱신(Interceptor)은 아직 미포함. 추후 추가 예정.
//

import Foundation
import Alamofire

final class APIClient {

    static let shared = APIClient()

    /// 토큰 불필요 엔드포인트(로그인/리프레시/로그아웃)용 — 인터셉터 없음
    private let publicSession: Session
    /// 인증 엔드포인트용 — Bearer 주입 + 401 자동 갱신
    private let authSession: Session

    private init() {
        let publicSession = Session()
        self.publicSession = publicSession
        // refresh는 인터셉터 없는 publicSession으로 호출 (무한 재귀 방지)
        self.authSession = Session(interceptor: AuthInterceptor(refreshSession: publicSession))
    }

    /// data가 있는 응답용. 디코딩한 T를 반환합니다.
    @discardableResult
    func request<T: Decodable>(_ target: TargetType, as type: T.Type = T.self) async throws -> T {
        let session = target.requiresAuth ? authSession : publicSession
        let response = await session
            .request(target)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response

        #if DEBUG
        NetworkLogger.log(response)
        #endif

        switch response.result {
        case .success(let data):
            return try decode(T.self, from: data)

        case .failure:
            // HTTP 응답 없음(연결 실패) → 네트워크
            guard let statusCode = response.response?.statusCode else {
                throw APIError.network
            }
            // 5xx → 네트워크 문구 (Android ApiErrorParser 규칙)
            if statusCode >= 500 {
                throw APIError.network
            }
            // 4xx → 서버 본문의 data.message
            if let data = response.data,
               let envelope = try? JSONDecoder().decode(APIResponse<APIErrorData>.self, from: data),
               let message = envelope.data?.message, !message.isEmpty {
                throw APIError.server(statusCode: statusCode, message: message)
            }
            // 메시지 파싱 불가 → 일반 오류
            throw APIError.unknown
        }
    }

    /// data 없이 message만 확인하면 되는 응답용. (로그아웃, 삭제 등)
    func requestVoid(_ target: TargetType) async throws {
        _ = try await request(target, as: EmptyData.self)
    }

    /// multipart/form-data 업로드 + 공통 Envelope 디코딩.
    @discardableResult
    func uploadMultipart<T: Decodable>(
        path: String,
        requiresAuth: Bool = true,
        builder: @escaping (MultipartFormData) -> Void,
        as type: T.Type = T.self
    ) async throws -> T {
        let url = BaseURL.current.appendingPathComponent(path)
        let session = requiresAuth ? authSession : publicSession
        let response = await session
            .upload(multipartFormData: builder, to: url, method: .post)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response

        #if DEBUG
        NetworkLogger.log(response)
        #endif

        switch response.result {
        case .success(let data):
            return try decode(T.self, from: data)
        case .failure:
            guard let statusCode = response.response?.statusCode else { throw APIError.network }
            if statusCode >= 500 { throw APIError.network }
            if let data = response.data,
               let envelope = try? JSONDecoder().decode(APIResponse<APIErrorData>.self, from: data),
               let message = envelope.data?.message, !message.isEmpty {
                throw APIError.server(statusCode: statusCode, message: message)
            }
            throw APIError.unknown
        }
    }

    // MARK: - Private

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // 204 No Content 등 본문이 비어있고 data가 필요 없는 응답(EmptyData)은 성공 처리
        if data.isEmpty, let empty = EmptyData() as? T {
            return empty
        }
        do {
            let envelope = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            guard let payload = envelope.data else {
                // data 자체를 기대했는데 비어있는 경우. EmptyData면 빈 인스턴스 허용.
                if let empty = EmptyData() as? T {
                    return empty
                }
                throw APIError.unknown
            }
            return payload
        } catch is DecodingError {
            throw APIError.unknown
        }
    }
}
