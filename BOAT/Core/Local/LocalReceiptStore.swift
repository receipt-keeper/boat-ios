//
//  LocalReceiptStore.swift
//  BOAT
//
//  영수증 로컬 캐시 저장소(SwiftData). 오프라인 조회를 위해 서버 응답을 로컬에 upsert하고,
//  네트워크 실패 시 로컬 데이터를 조건에 맞게 필터/정렬해 반환한다. Android ReceiptDao 대응.
//

import Foundation
import SwiftData

@MainActor
final class LocalReceiptStore {

    static let shared = LocalReceiptStore()

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    private init() {
        do {
            container = try ModelContainer(for: ReceiptEntity.self)
        } catch {
            // 로컬 캐시 초기화 실패 시 메모리 전용으로 폴백 (앱 크래시 방지)
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: ReceiptEntity.self, configurations: config)
        }
    }

    // MARK: - 쓰기

    /// 단일 영수증 upsert (영수증 등록 성공 직후 호출)
    func upsert(_ receipt: Receipt) {
        if let existing = fetchEntity(id: receipt.receiptId) {
            existing.update(from: receipt)
        } else {
            context.insert(ReceiptEntity(from: receipt))
        }
        try? context.save()
    }

    /// 목록 응답을 일괄 upsert (첫 페이지 조회 성공 시 캐시 동기화)
    func upsertAll(_ receipts: [Receipt]) {
        for receipt in receipts {
            if let existing = fetchEntity(id: receipt.receiptId) {
                existing.update(from: receipt)
            } else {
                context.insert(ReceiptEntity(from: receipt))
            }
        }
        try? context.save()
    }

    func delete(id: String) {
        if let existing = fetchEntity(id: id) {
            context.delete(existing)
            try? context.save()
        }
    }

    func clear() {
        try? context.delete(model: ReceiptEntity.self)
        try? context.save()
    }

    // MARK: - 읽기 (오프라인 폴백)

    /// 로컬 전체 조회 후 조건(status/category/q)에 맞게 필터 + 정렬. Android 오프라인 폴백 로직 대응.
    func query(status: String, sort: String, category: String?, q: String?) -> [Receipt] {
        let all = fetchAll().map { $0.toReceipt() }

        let filtered = all.filter { receipt in
            matchesStatus(receipt, status: status)
                && matchesCategory(receipt, category: category)
                && matchesQuery(receipt, q: q)
        }

        return sorted(filtered, by: sort)
    }

    var isEmpty: Bool { fetchAll().isEmpty }

    // MARK: - Private

    private func fetchEntity(id: String) -> ReceiptEntity? {
        let descriptor = FetchDescriptor<ReceiptEntity>(
            predicate: #Predicate { $0.receiptId == id }
        )
        return try? context.fetch(descriptor).first
    }

    private func fetchAll() -> [ReceiptEntity] {
        (try? context.fetch(FetchDescriptor<ReceiptEntity>())) ?? []
    }

    private func matchesStatus(_ r: Receipt, status: String) -> Bool {
        switch status {
        case "expiring":
            let d = r.warrantyDDay ?? 0
            return d >= 0 && d <= Receipt.expiringThresholdDays
        case "expired":
            return (r.warrantyDDay ?? 0) < 0
        default: // "all"
            return true
        }
    }

    private func matchesCategory(_ r: Receipt, category: String?) -> Bool {
        guard let category, !category.isEmpty else { return true }
        // 공백/표기 편차 흡수 후 비교 ("주방 가전"/"주방가전" 등)
        return DeviceCategory.normalizeCategory(r.category) == DeviceCategory.normalizeCategory(category)
    }

    private func matchesQuery(_ r: Receipt, q: String?) -> Bool {
        guard let q, !q.isEmpty else { return true }
        let keyword = q.lowercased()
        if r.itemName.lowercased().contains(keyword) { return true }
        if let brand = r.brandName?.lowercased(), brand.contains(keyword) { return true }
        return false
    }

    private func sorted(_ receipts: [Receipt], by sort: String) -> [Receipt] {
        switch sort {
        case "expiresOn":
            // 만료 임박 순 (만료일 오름차순, 없으면 뒤로)
            return receipts.sorted { ($0.expiresOn ?? "9999") < ($1.expiresOn ?? "9999") }
        case "purchaseDate":
            // 구매일 최신순
            return receipts.sorted { ($0.paymentDate ?? "") > ($1.paymentDate ?? "") }
        default: // "recent"
            // 등록일 최신순 (registeredAt 없으면 캐시 순서 보존을 위해 그대로)
            return receipts.sorted { ($0.registeredAt ?? "") > ($1.registeredAt ?? "") }
        }
    }
}
