//
//  AppDelegate.swift
//  BOAT
//
//  FCM 푸시 수신을 위한 앱 델리게이트.
//  - APNs 등록 → APNs 토큰을 FCM(Messaging)에 연결
//  - MessagingDelegate: FCM 등록 토큰 발급/갱신 시 서버 재등록 (Android onNewToken 대응)
//  - UNUserNotificationCenterDelegate: 포그라운드 배너 표시 + 탭 처리
//
//  ※ Firebase 설정(FirebaseApp.configure)은 BOATApp.init에서 먼저 수행된다.
//

import UIKit
import FirebaseMessaging
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        // 알림 표시 권한과 무관하게 APNs 토큰을 확보해 서버에 디바이스 등록한다.
        // (표시 권한은 별도로 AS 알림 설정에서 요청 — PermissionManager)
        application.registerForRemoteNotifications()
        return true
    }

    // APNs 디바이스 토큰 → FCM 연결
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // 시뮬레이터 등에서 APNs 등록 실패 가능 — 조용히 무시 (푸시 미지원 환경)
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {}
}

// MARK: - FCM 등록 토큰 수신/갱신

extension AppDelegate: MessagingDelegate {
    /// 토큰 최초 발급/갱신 콜백. 로그인 상태면 서버에 재등록한다. (Android onNewToken 대응)
    /// 미로그인 상태에서는 FCMDeviceManager가 등록을 건너뛴다(인증 헤더 없음).
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task { await FCMDeviceManager.shared.registerToken(fcmToken) }
    }
}

// MARK: - 알림 표시/탭 처리

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// 포그라운드에서도 배너/사운드 노출 (Android가 포그라운드에서 직접 표시하는 것과 동일 취지)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }

    /// 푸시 탭 → 페이로드의 resourceType/resourceId로 라우팅(현재는 receipt만).
    /// NotificationRouter가 값을 들고 있으면 MainTabView가 관찰해 상세 화면을 띄운다.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        await NotificationRouter.shared.handle(
            resourceType: userInfo["resourceType"] as? String,
            resourceId: userInfo["resourceId"] as? String
        )
    }
}
