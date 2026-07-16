//
//  BaseURL.swift
//  BOAT
//
//  서버 Base URL을 한 곳에서 관리합니다.
//  DEBUG 빌드: DebugConfig.shared.useLocalServer 값에 따라 런타임 전환 가능.
//  RELEASE 빌드: 항상 배포 서버 URL 고정.
//

import Foundation

enum BaseURL {
    private static let production = URL(string: "https://api.boatlab.co.kr")!
    private static let local      = URL(string: "http://localhost:8000")!

    /// TestFlight로 설치된 빌드인지 여부 (App Store 정식 배포와 구분). AppEnvironment에서도 재사용.
    static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    static var current: URL {
        #if DEBUG
        let allowToggle = true
        #else
        let allowToggle = isTestFlight
        #endif
        guard allowToggle, DebugConfig.shared.useLocalServer else { return production }
        return local
    }
}
