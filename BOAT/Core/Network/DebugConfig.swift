//
//  DebugConfig.swift
//  BOAT
//
//  DEBUG 전용 개발 설정. 릴리즈 빌드에서는 컴파일에서 완전히 제외된다.
//  현재: 서버 Base URL 전환 (배포 서버 ↔ localhost:8000)
//

#if DEBUG
import Foundation

@Observable
final class DebugConfig {
    static let shared = DebugConfig()

    /// true이면 http://localhost:8000 을 Base URL로 사용.
    var useLocalServer: Bool {
        didSet {
            UserDefaults.standard.set(useLocalServer, forKey: "boat.debug.useLocalServer")
        }
    }

    private init() {
        useLocalServer = UserDefaults.standard.bool(forKey: "boat.debug.useLocalServer")
    }
}
#endif
