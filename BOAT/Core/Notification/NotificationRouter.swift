//
//  NotificationRouter.swift
//  BOAT
//
//  푸시 알림 탭 → 읽음 처리 + 리소스 라우팅. AppDelegate(didReceive response:)가 페이로드를
//  전달하면 읽음 처리 후, MainTabView가 관찰해 영수증 상세로 이동한다.
//  (인앱 알림 목록 카드 탭과 동일 정책)
//

import Foundation

@MainActor
@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()
    private init() {}

    /// receipt 리소스로 이동해야 하면 non-nil. 라우팅 소비 후 반드시 nil로 되돌릴 것.
    var pendingReceiptId: String?

    /// 푸시 payload를 해석해 읽음 처리 + 라우팅 대상을 세팅한다.
    /// - notificationId가 있으면 리소스 종류와 무관하게 항상 읽음 처리(best-effort, 인앱 카드 탭과 동일 정책).
    /// - resourceType이 "receipt"고 resourceId가 있으면 영수증 상세로 이동시킨다.
    func handle(notificationId: String?, resourceType: String?, resourceId: String?) {
        if let notificationId, !notificationId.isEmpty {
            Task { await NotificationRepository.shared.markRead(id: notificationId) }
        }
        guard resourceType == "receipt", let resourceId, !resourceId.isEmpty else { return }
        pendingReceiptId = resourceId
    }
}
