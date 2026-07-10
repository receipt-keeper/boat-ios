//
//  NotificationRouter.swift
//  BOAT
//
//  푸시 알림 탭 → 읽음 처리 + 리소스 라우팅. AppDelegate(didReceive response:)가 페이로드를
//  전달하면 읽음 처리 후, MainTabView가 관찰해 영수증 상세/홈으로 이동한다.
//  (인앱 알림 목록 카드 탭과 동일 정책 — NotificationListView.handleTap도 이 라우터를 공유한다)
//

import Foundation

@MainActor
@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()
    private init() {}

    /// receipt 리소스로 이동해야 하면 non-nil. 라우팅 소비 후 반드시 nil로 되돌릴 것.
    var pendingReceiptId: String?
    /// true면 홈 탭으로 이동해야 함(messageType=marketing). 소비 후 반드시 false로 되돌릴 것.
    var shouldOpenHome = false

    /// 푸시 payload를 해석해 읽음 처리 + 라우팅 대상을 세팅한다.
    /// - notificationId가 있으면 리소스 종류와 무관하게 항상 읽음 처리(best-effort, 인앱 카드 탭과 동일 정책).
    /// - messageType이 "marketing"이면 홈 탭으로 이동(리소스 라우팅보다 우선).
    /// - 그 외 resourceType이 "receipt"고 resourceId가 있으면 영수증 상세로 이동시킨다.
    func handle(notificationId: String?, messageType: String?, resourceType: String?, resourceId: String?) {
        if let notificationId, !notificationId.isEmpty {
            Task { await NotificationRepository.shared.markRead(id: notificationId) }
        }
        if messageType == "marketing" {
            shouldOpenHome = true
            return
        }
        guard resourceType == "receipt", let resourceId, !resourceId.isEmpty else { return }
        pendingReceiptId = resourceId
    }
}
