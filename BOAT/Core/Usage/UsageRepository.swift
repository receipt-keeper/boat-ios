//
//  UsageRepository.swift
//  BOAT
//
//  AI 분석 이용 가능 여부 조회. GET /api/v1/usage
//

import Foundation

// MARK: - Model

struct OcrUsage: Decodable {
    let canAnalyze: Bool
    let remainingCount: Int
}

private struct UsagePayload: Decodable {
    let ocr: OcrUsage
}

// MARK: - Repository

@MainActor
final class UsageRepository {
    static let shared = UsageRepository()
    private init() {}

    /// GET /api/v1/usage — OCR 이용 가능 여부 반환.
    func fetchUsage() async throws -> OcrUsage {
        let payload: UsagePayload = try await APIClient.shared.request(UsageTarget.getUsage)
        return payload.ocr
    }
}
