//
//  AdsConfig.swift
//  BOAT
//
//  Google AdMob 광고 단위 ID 설정.
//  Android(BoatNativeAd.kt)는 ca-app-pub-3833104326342504/7840881439를 쓰고 있지만,
//  AdMob은 플랫폼별로 앱을 별도 등록해야 해서 Android의 App ID/광고 단위 ID를 iOS에
//  그대로 재사용할 수 없다 — AdMob 콘솔에서 iOS 앱을 새로 등록해 발급받은 ID로 교체해야 한다.
//  그 전까지는 구글 공식 iOS 테스트 ID를 사용한다(Info.plist의 GADApplicationIdentifier도 동일).
//

import Foundation

enum AdsConfig {
    /// 네이티브 광고 단위 ID. 구글 공식 iOS 네이티브(고급) 테스트 ID.
    /// TODO: AdMob 콘솔에서 iOS 앱을 등록해 발급받은 실제 ID로 교체.
    static let nativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
}
