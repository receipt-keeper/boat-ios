//
//  InstallAnalytics.swift
//  BOAT
//
//  앱 설치 후 최초 실행 시 Firebase Analytics에 커스텀 이벤트 "app_install"을 1회만 기록.
//

import FirebaseAnalytics
import Foundation

enum InstallAnalytics {
    private static let loggedKey = "boat.analytics.appInstallLogged"

    /// 앱 프로세스 시작 시 호출 — 이번 기기에서 처음 실행하는 경우에만 app_install 이벤트를 남긴다.
    static func logInstallIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: loggedKey) else { return }
        Analytics.logEvent("app_install", parameters: nil)
        UserDefaults.standard.set(true, forKey: loggedKey)
    }
}
