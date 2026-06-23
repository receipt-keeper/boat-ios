//
//  UserStore.swift
//  BOAT
//
//  유저 데이터 로컬 저장소. UserDefaults에 영속화. (Android DataStore 대응)
//  토큰 같은 비밀값은 KeychainManager, 프로필/설정 데이터는 여기서 관리한다.
//

import Foundation

@Observable
final class UserStore {

    static let shared = UserStore()

    private let key = "com.windrr.boat.currentUser"
    private let defaults = UserDefaults.standard

    /// 현재 유저. 로그인 전/로그아웃 후에는 nil.
    private(set) var current: User?

    private init() {
        if let data = defaults.data(forKey: key),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            current = user
        }
    }

    /// 유저 전체 저장(덮어쓰기)
    func save(_ user: User) {
        current = user
        persist()
    }

    /// 일부 필드만 갱신 (예: 토큰 차감, 토글 변경)
    func update(_ transform: (inout User) -> Void) {
        guard var user = current else { return }
        transform(&user)
        current = user
        persist()
    }

    /// 로그아웃/탈퇴 시 정리
    func clear() {
        current = nil
        defaults.removeObject(forKey: key)
    }

    private func persist() {
        guard let user = current, let data = try? JSONEncoder().encode(user) else { return }
        defaults.set(data, forKey: key)
    }
}
