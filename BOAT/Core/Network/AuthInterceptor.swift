//
//  AuthInterceptor.swift
//  BOAT
//
//  Android TokenInterceptor + TokenAuthenticator 에 대응.
//  - adapt: 모든 요청에 Bearer AccessToken 자동 주입
//  - retry: 401 응답 시 RefreshToken으로 재발급 후 원 요청 재시도
//           재발급마저 실패하면 토큰 삭제 + 세션 만료 알림(→ 로그아웃)
//
//  refresh 호출은 인터셉터가 없는 별도 세션(refreshSession)을 사용해
//  만료 토큰 주입과 무한 재귀(refresh가 또 401 → retry 재진입)를 방지한다.
//

import Foundation
import Alamofire

extension Notification.Name {
    /// 토큰 재발급 실패 → 강제 로그아웃 신호
    static let boatSessionExpired = Notification.Name("boatSessionExpired")
}

final class AuthInterceptor: RequestInterceptor {

    private let refreshSession: Session

    private let lock = NSLock()
    private var isRefreshing = false
    private var pendingCompletions: [(RetryResult) -> Void] = []

    init(refreshSession: Session) {
        self.refreshSession = refreshSession
    }

    // MARK: - Adapt (토큰 주입)

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var request = urlRequest
        if let token = KeychainManager.shared.accessToken {
            request.headers.add(.authorization(bearerToken: token))
        }
        completion(.success(request))
    }

    // MARK: - Retry (401 → 갱신 후 재시도)

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetry)
            return
        }

        lock.lock()

        // 이미 다른 요청이 갱신을 끝냈다면(요청에 쓰인 토큰 ≠ 현재 토큰) 바로 재시도
        let usedToken = request.request?
            .value(forHTTPHeaderField: "Authorization")?
            .replacingOccurrences(of: "Bearer ", with: "")
        if let current = KeychainManager.shared.accessToken, current != usedToken {
            lock.unlock()
            completion(.retry)
            return
        }

        // 갱신 진행 중이면 대기열에 추가하고 결과를 함께 기다린다 (중복 refresh 방지)
        pendingCompletions.append(completion)
        if isRefreshing {
            lock.unlock()
            return
        }
        isRefreshing = true
        lock.unlock()

        performRefresh { [weak self] success in
            guard let self else { return }
            self.lock.lock()
            let waiting = self.pendingCompletions
            self.pendingCompletions.removeAll()
            self.isRefreshing = false
            self.lock.unlock()
            waiting.forEach { $0(success ? .retry : .doNotRetry) }
        }
    }

    // MARK: - Refresh

    private func performRefresh(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = KeychainManager.shared.refreshToken, !refreshToken.isEmpty else {
            forceLogout()
            completion(false)
            return
        }

        refreshSession
            .request(AuthTarget.refresh(refreshToken: refreshToken))
            .validate(statusCode: 200..<300)
            .responseData { [weak self] response in
                guard let self else { return }

                #if DEBUG
                NetworkLogger.log(response)
                #endif

                switch response.result {
                case .success(let data):
                    if let envelope = try? JSONDecoder().decode(APIResponse<LoginTokenData>.self, from: data),
                       let tokens = envelope.data {
                        KeychainManager.shared.accessToken = tokens.accessToken
                        KeychainManager.shared.refreshToken = tokens.refreshToken
                        completion(true)
                    } else {
                        self.forceLogout()
                        completion(false)
                    }
                case .failure:
                    // refresh 401(회전된 토큰 재사용 등) 또는 네트워크 실패 → 로그아웃
                    self.forceLogout()
                    completion(false)
                }
            }
    }

    private func forceLogout() {
        KeychainManager.shared.clearAll()
        NotificationCenter.default.post(name: .boatSessionExpired, object: nil)
    }
}
