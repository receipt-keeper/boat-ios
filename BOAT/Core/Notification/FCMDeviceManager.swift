//
//  FCMDeviceManager.swift
//  BOAT
//
//  FCM 디바이스(등록 토큰) 등록/해제 관리. Android FcmDeviceManager 대응.
//
//  정책:
//  - register():      로그인/홈 진입 시 현재 토큰 조회 후 서버에 멱등 upsert.
//  - registerToken(): MessagingDelegate 콜백(토큰 갱신)에서 새 토큰으로 직접 등록.
//  - unregister():    로그아웃 시 토큰 삭제 "전"에 호출(인증 헤더 필요). best-effort.
//    FCM 토큰 자체(deleteToken)는 지우지 않는다 — 재로그인 직후 발송 실패(UNREGISTERED) 방지.
//

import Foundation
import FirebaseMessaging

@MainActor
final class FCMDeviceManager {

    static let shared = FCMDeviceManager()
    private init() {}

    private var isLoggedIn: Bool { KeychainManager.shared.accessToken != nil }

    /// 현재 FCM 토큰을 조회해 서버에 등록 (로그인/홈 진입 시). 멱등이라 반복 호출 안전.
    func register() async {
        guard isLoggedIn else { return }
        guard let token = try? await Messaging.messaging().token() else { return }
        await registerToken(token)
    }

    /// 주어진 토큰을 서버에 등록(멱등 upsert). 성공 시 로컬 캐시에 저장.
    func registerToken(_ token: String) async {
        guard isLoggedIn else { return }
        do {
            try await APIClient.shared.requestVoid(NotificationDeviceTarget.register(token: token))
            FCMTokenStore.registeredToken = token
        } catch {
            // best-effort — 다음 진입/갱신 시 재시도
        }
    }

    /// 로그아웃 시 디바이스 해제. 마지막 등록 토큰 우선, 없으면 현재 토큰 조회. best-effort.
    func unregister() async {
        var token = FCMTokenStore.registeredToken
        if token == nil {
            token = try? await Messaging.messaging().token()
        }
        if let token {
            try? await APIClient.shared.requestVoid(NotificationDeviceTarget.unregister(token: token))
        }
        FCMTokenStore.registeredToken = nil
    }
}
