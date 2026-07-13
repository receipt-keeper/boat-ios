//
//  ConsentManager.swift
//  BOAT
//
//  광고 노출 전 동의 처리 — Android 구현엔 없는 부분이지만, iOS는 앱스토어 심사 정책상
//  광고 SDK 사용 시 ATT(App Tracking Transparency) 프롬프트가 사실상 필수이고,
//  구글 UMP(GDPR/개인정보보호법 동의) SDK로 광고 개인화 동의를 먼저 받아야 한다.
//
//  흐름: UMP 동의 정보 갱신 → (필요 시) 동의 폼 노출 → ATT 권한 요청 → Mobile Ads SDK 시작.
//

import AppTrackingTransparency
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

@MainActor
enum ConsentManager {

    /// 앱 시작 시 1회 호출 — 동의/추적 권한을 순서대로 확인한 뒤 Mobile Ads SDK를 시작한다.
    /// 광고 자체는 동의 절차와 무관하게(비개인화 광고로라도) 노출 가능해야 하므로,
    /// 동의 폼 로드 실패 등 어떤 단계에서 문제가 생겨도 항상 마지막엔 start()를 호출한다.
    static func requestConsentAndStart() async {
        await requestUMPConsentIfNeeded()
        await requestTrackingAuthorizationIfNeeded()
        MobileAds.shared.start(completionHandler: nil)
    }

    // MARK: - UMP (구글 사용자 메시지 플랫폼) 동의

    private static func requestUMPConsentIfNeeded() async {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    CrashReporter.record(error)
                    continuation.resume()
                    return
                }
                Task {
                    await loadAndPresentFormIfRequired()
                    continuation.resume()
                }
            }
        }
    }

    private static func loadAndPresentFormIfRequired() async {
        guard ConsentInformation.shared.formStatus == .available else { return }
        guard let viewController = UIApplication.boatRootViewController else { return }

        await withCheckedContinuation { continuation in
            ConsentForm.load { form, loadError in
                if let loadError {
                    CrashReporter.record(loadError)
                    continuation.resume()
                    return
                }
                guard ConsentInformation.shared.consentStatus == .required else {
                    continuation.resume()
                    return
                }
                form?.present(from: viewController) { _ in
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - ATT (App Tracking Transparency)

    private static func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }

}
