//
//  FCMTokenStore.swift
//  BOAT
//
//  서버에 마지막으로 등록 성공한 FCM registration token을 캐시한다.
//  로그아웃 시 디바이스 해제(DELETE)에 이 값을 사용해, 토큰이 회전된 경우에도
//  서버에 등록해둔 바로 그 토큰으로 정확히 해제한다. Android FcmDeviceStore 대응.
//

import Foundation

enum FCMTokenStore {
    private static let key = "com.receipt-keeper.BOAT.fcmRegisteredToken"

    static var registeredToken: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}
