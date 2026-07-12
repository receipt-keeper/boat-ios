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

    /// 요청 타임아웃(초). OCR 분석처럼 응답이 오래 걸리는 요청이 15초 만에 잘려
    /// 실패 처리되는 문제가 있어, Android(ApiClient.kt TIMEOUT_SECONDS)와 동일하게 60초로 맞춘다.
    private static let requestTimeout: TimeInterval = 60

    /// 토큰 불필요 엔드포인트(로그인/리프레시/로그아웃)용 — 인터셉터 없음
    private let publicSession: Session
    /// 인증 엔드포인트용 — Bearer 주입 + 401 자동 갱신
    private let authSession: Session

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Self.requestTimeout
        configuration.timeoutIntervalForResource = Self.requestTimeout

        let publicSession = Session(configuration: configuration)
        self.publicSession = publicSession
        // refresh는 인터셉터 없는 publicSession으로 호출 (무한 재귀 방지)
        self.authSession = Session(configuration: configuration, interceptor: AuthInterceptor(refreshSession: publicSession))
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
                Self.reportNetworkFailure(path: target.path, method: target.method.rawValue, statusCode: nil, underlyingError: response.error)
                throw APIError.network
            }
            // 5xx → 네트워크 문구 (Android ApiErrorParser 규칙)
            if statusCode >= 500 {
                Self.reportNetworkFailure(path: target.path, method: target.method.rawValue, statusCode: statusCode, underlyingError: response.error)
                throw APIError.network
            }
            // 4xx → 상태코드는 항상 보존 (404 판별 등에 필요), 메시지는 서버 본문 우선
            let parsed = Self.parseError(from: response.data)
            throw APIError.server(statusCode: statusCode, message: parsed.message, fieldErrors: parsed.fieldErrors)
        }
    }

    /// data 없이 message만 확인하면 되는 응답용. (로그아웃, 삭제 등)
    func requestVoid(_ target: TargetType) async throws {
        _ = try await request(target, as: EmptyData.self)
    }

    /// 공통 Envelope(JSON)이 아닌 원본 바이너리 응답용. (첨부 파일 원본 조회 등)
    /// Bearer 토큰 자동 주입 + 401 자동 갱신은 authSession 재사용으로 동일하게 적용된다.
    func requestData(_ target: TargetType) async throws -> Data {
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
            return data
        case .failure:
            guard let statusCode = response.response?.statusCode else {
                Self.reportNetworkFailure(path: target.path, method: target.method.rawValue, statusCode: nil, underlyingError: response.error)
                throw APIError.network
            }
            if statusCode >= 500 {
                Self.reportNetworkFailure(path: target.path, method: target.method.rawValue, statusCode: statusCode, underlyingError: response.error)
                throw APIError.network
            }
            throw APIError.server(statusCode: statusCode, message: String(localized: "error.api.unknown"), fieldErrors: [])
        }
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
            guard let statusCode = response.response?.statusCode else {
                Self.reportNetworkFailure(path: path, method: "POST", statusCode: nil, underlyingError: response.error)
                throw APIError.network
            }
            if statusCode >= 500 {
                Self.reportNetworkFailure(path: path, method: "POST", statusCode: statusCode, underlyingError: response.error)
                throw APIError.network
            }
            let parsed = Self.parseError(from: response.data)
            throw APIError.server(statusCode: statusCode, message: parsed.message, fieldErrors: parsed.fieldErrors)
        }
    }

    // MARK: - Private

    /// 연결 실패(타임아웃/오프라인 등) 또는 5xx로 인한 네트워크 통신 실패 시,
    /// 어떤 요청이 왜 실패했는지 Crashlytics에 non-fatal로 남긴다.
    private static func reportNetworkFailure(path: String, method: String, statusCode: Int?, underlyingError: Error?) {
        CrashReporter.setValue(path, forKey: "api_failed_path")
        CrashReporter.setValue(method, forKey: "api_failed_method")
        if let statusCode {
            CrashReporter.setValue(statusCode, forKey: "api_failed_status_code")
        }
        CrashReporter.record(underlyingError ?? APIError.network)
    }

    /// 실패 응답 본문에서 사용자 노출 문구 + 필드별 에러 목록(data.errors)을 꺼낸다.
    /// 문구는 errors 목록이 있으면 첫 번째 필드 에러 메시지를 우선하고, 없으면 data.message를 사용한다.
    /// (Android ApiErrorParser.parseMessage와 동일 규칙)
    private static func parseError(from data: Data?) -> (message: String, fieldErrors: [APIErrorData.FieldError]) {
        guard let data,
              let envelope = try? JSONDecoder().decode(APIResponse<APIErrorData>.self, from: data) else {
            return (String(localized: "error.api.unknown"), [])
        }
        let fieldErrors = envelope.data?.errors ?? []
        if let fieldMessage = fieldErrors.first?.message, !fieldMessage.isEmpty {
            return (fieldMessage, fieldErrors)
        }
        if let message = envelope.data?.message, !message.isEmpty {
            return (message, fieldErrors)
        }
        return (String(localized: "error.api.unknown"), fieldErrors)
    }

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
