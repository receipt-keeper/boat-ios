//
//  CreditRepository.swift
//  BOAT
//
//  크레딧(무료 분석 토큰) 모델 + 인메모리 스토어 + 데이터 접근.
//  GET /api/v1/credits 조회 후 CreditStore에 캐시.
//

import Foundation

// MARK: - Model

/// GET /api/v1/credits 의 data 페이로드
struct Credit: Decodable {
    let remainingCount: Int
    let totalGrantedCount: Int
    let usedCount: Int
}

// MARK: - Store

@Observable
final class CreditStore {
    static let shared = CreditStore()
    var current: Credit?
    private init() {}

    func save(_ credit: Credit) { current = credit }
    func clear() { current = nil }
}

// MARK: - Repository

@MainActor
final class CreditRepository {
    static let shared = CreditRepository()
    private let store = CreditStore.shared
    private init() {}

    /// GET /api/v1/credits — 서버에서 조회 후 CreditStore에 캐시.
    @discardableResult
    func fetchCredits() async throws -> Credit {
        let credit: Credit = try await APIClient.shared.request(CreditTarget.getCredits)
        store.save(credit)
        return credit
    }

    func clear() { store.clear() }
}
