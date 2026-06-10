//
//  KeychainManager.swift
//  BOAT
//
//  iOS Keychain을 통해 서버 발급 JWT(Access/Refresh Token)를 안전하게 저장/조회/삭제합니다.
//  Android의 DataStore에 대응하는 iOS 보안 저장소입니다.
//

import Foundation
import Security

final class KeychainManager {

    static let shared = KeychainManager()
    private init() {}

    // MARK: - Keys

    private enum Key: String {
        case accessToken  = "com.receipt-keeper.BOAT.accessToken"
        case refreshToken = "com.receipt-keeper.BOAT.refreshToken"
    }

    // MARK: - Public Interface

    var accessToken: String? {
        get { read(key: .accessToken) }
        set { save(key: .accessToken, value: newValue) }
    }

    var refreshToken: String? {
        get { read(key: .refreshToken) }
        set { save(key: .refreshToken, value: newValue) }
    }

    func clearAll() {
        delete(key: .accessToken)
        delete(key: .refreshToken)
    }

    // MARK: - Private

    private func save(key: Key, value: String?) {
        guard let value else {
            delete(key: key)
            return
        }

        guard let data = value.data(using: .utf8) else { return }

        // 기존 값 있으면 업데이트, 없으면 새로 저장
        if read(key: key) != nil {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key.rawValue
            ]
            let attributes: [CFString: Any] = [kSecValueData: data]
            SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key.rawValue,
                kSecValueData: data,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
            ]
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    private func read(key: Key) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }

        return value
    }

    private func delete(key: Key) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }
}
