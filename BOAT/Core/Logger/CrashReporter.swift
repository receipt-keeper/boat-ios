//
//  CrashReporter.swift
//  BOAT
//
//  Firebase Crashlytics를 앱 전역에서 일관되게 사용하기 위한 래퍼입니다.
//  Crashlytics API를 직접 호출하는 대신 이 타입을 거치면,
//  추후 로깅 정책 변경(다른 SDK 교체 등)이 있어도 호출부를 건드릴 필요가 없습니다.
//
//  Crashlytics는 FirebaseApp.configure() 시점에 자동으로 활성화되어
//  치명적 크래시(fatal)는 별도 코드 없이 수집됩니다.
//  이 래퍼는 "비치명적 에러 기록 / 커스텀 로그 / 사용자 식별" 같은
//  부가 기능을 다룰 때 사용합니다.
//

import Foundation
import FirebaseCrashlytics

enum CrashReporter {

    /// 잡았지만 크래시는 아닌 에러를 Crashlytics에 기록합니다. (non-fatal)
    /// 예: API 실패, 디코딩 실패 등 복구 가능한 예외.
    static func record(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }

    /// 크래시 발생 시 함께 전송될 커스텀 로그를 남깁니다.
    /// 크래시 직전 사용자 행동 추적에 유용합니다.
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    /// 크래시 리포트에 첨부될 커스텀 키-값을 설정합니다.
    /// 예: 현재 화면, 선택된 공간 ID 등.
    static func setValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }

    /// 로그인한 사용자를 식별합니다. (로그아웃 시 nil로 초기화)
    /// 개인정보가 아닌 내부 식별자(Firebase UID 등)를 사용하세요.
    static func setUserID(_ userID: String?) {
        Crashlytics.crashlytics().setUserID(userID ?? "")
    }
}
