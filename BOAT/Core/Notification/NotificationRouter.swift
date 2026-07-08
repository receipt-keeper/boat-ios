//
//  NotificationRouter.swift
//  BOAT
//
//  푸시 알림 탭 → 리소스 라우팅. AppDelegate(didReceive response:)가 페이로드를 해석해
//  세팅하면, MainTabView가 관찰해 영수증 상세로 이동한다. (인앱 알림 목록 카드 탭과 동일 정책)
//

import Foundation

@MainActor
@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()
    private init() {}

    /// receipt 리소스로 이동해야 하면 non-nil. 라우팅 소비 후 반드시 nil로 되돌릴 것.
    var pendingReceiptId: String?

    /// 푸시 payload의 resourceType/resourceId를 해석해 라우팅 대상을 세팅한다.
    /// resourceType이 "receipt"가 아니거나 resourceId가 없으면 아무 것도 하지 않는다.
    func handle(resourceType: String?, resourceId: String?) {
        guard resourceType == "receipt", let resourceId, !resourceId.isEmpty else { return }
        pendingReceiptId = resourceId
    }
}
