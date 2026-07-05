//
//  AppEnvironment.swift
//  BOAT
//
//  [TEST] 전용 UI(디버그 버튼 등)의 노출 조건. DEBUG 빌드뿐 아니라 TestFlight 배포본에서도
//  PM/QA가 확인할 수 있어야 하므로, 실제 App Store 정식 배포본에서만 숨긴다.
//

import Foundation

enum AppEnvironment {
    /// DEBUG 빌드이거나 TestFlight로 설치된 빌드. false면 App Store 정식 배포본.
    static var isDebugOrTestFlight: Bool {
        #if DEBUG
        return true
        #else
        return BaseURL.isTestFlight
        #endif
    }
}
