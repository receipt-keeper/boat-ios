//
//  FeedbackTrigger.swift
//  BOAT
//
//  영수증 등록 등 특정 액션 성공 시 홈 화면에서 피드백 시트를 띄우기 위한 전역 트리거.
//  Android FeedbackTrigger 대응.
//

import Foundation

@MainActor
@Observable
final class FeedbackTrigger {
    static let shared = FeedbackTrigger()
    private init() {}

    /// 값 변경 자체가 신호 — MainTabView가 이 값의 변화를 관찰해 UserFeedbackStore.tryShowFeedback()을 호출한다.
    private(set) var triggerCount = 0

    func trigger() {
        triggerCount += 1
    }
}
