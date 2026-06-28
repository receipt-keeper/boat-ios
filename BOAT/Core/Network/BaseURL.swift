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
    private static let production = URL(string: "https://boatlab-dev.luigi99.cloud")!
    private static let local      = URL(string: "http://localhost:8000")!

    static var current: URL {
        #if DEBUG
        return DebugConfig.shared.useLocalServer ? local : production
        #else
        return production
        #endif
    }
}
