//
//  UserFeedbackStore.swift
//  BOAT
//
//  서비스 만족도 피드백 시트 상태 관리 + Firebase Analytics 전송.
//  Android UserFeedbackViewModel 대응.
//

import FirebaseAnalytics
import Foundation

@MainActor
@Observable
final class UserFeedbackStore {
    static let shared = UserFeedbackStore()
    private init() {}

    var showFeedbackSheet = false

    /// 앱 프로세스 내에서 이미 한 번 노출을 시도했으면 다시 시도하지 않는다(Android hasTriggeredInSession 대응).
    private var hasTriggeredInSession = false
    private static let nextDisplayAtKey = "boat.feedback.nextDisplayAt"

    /// 피드백 시트 노출 시도 — 재노출 제한(기본 30일, "다음에"는 15일)을 확인한 후 조건을 만족하면 띄운다.
    func tryShowFeedback() {
        guard !hasTriggeredInSession else { return }
        let nextDisplayAt = UserDefaults.standard.double(forKey: Self.nextDisplayAtKey)
        guard Date().timeIntervalSince1970 >= nextDisplayAt else { return }
        showFeedbackSheet = true
        hasTriggeredInSession = true
    }

    /// 피드백 제출 — Firebase Analytics에 이벤트 전송 후 30일 재노출 제한을 설정한다.
    @discardableResult
    func submitFeedback(rating: Int, comment: String) -> Bool {
        Analytics.logEvent("service_feedback", parameters: [
            "rating": rating,
            "comment": comment,
        ])
        deferFeedback(days: 30)
        showFeedbackSheet = false
        return true
    }

    /// X 버튼/외부 탭으로 닫기 — 30일 재노출 제한.
    func onFeedbackDismissed() {
        deferFeedback(days: 30)
        showFeedbackSheet = false
    }

    /// "다음에" 버튼 — 15일 재노출 제한.
    func onFeedbackPostponed() {
        deferFeedback(days: 15)
        showFeedbackSheet = false
    }

    private func deferFeedback(days: Int) {
        let next = Date().addingTimeInterval(TimeInterval(days * 86400))
        UserDefaults.standard.set(next.timeIntervalSince1970, forKey: Self.nextDisplayAtKey)
    }
}
