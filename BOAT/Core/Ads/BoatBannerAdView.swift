//
//  BoatBannerAdView.swift
//  BOAT
//
//  구글 표준 배너 광고. 네이티브 광고 대신 배너 형식으로 전환 —
//  구글이 완성된 광고 크리에이티브를 그려주므로 커스텀 레이아웃 없이 BannerView를 감싸기만 한다.
//  로드 실패 시 기존 AccessoryBanner로 폴백한다.
//

import GoogleMobileAds
import SwiftUI

struct BoatBannerAdView: View {
    var adUnitID: String = AdsConfig.bannerAdUnitID

    @State private var loader = BannerAdLoader()

    /// 표준 배너 크기(320x50) 고정.
    private static let bannerSize = CGSize(width: 320, height: 50)

    var body: some View {
        Group {
            if loader.didLoad {
                BannerContainerView(bannerView: loader.bannerView)
                    .frame(width: Self.bannerSize.width, height: Self.bannerSize.height)
                    .frame(maxWidth: .infinity)
            } else if loader.didFail {
                // 광고 로드 실패 시 기존 임시 배너로 폴백 (Android 동일)
                AccessoryBanner()
            } else {
                Color.clear.frame(height: Self.bannerSize.height)
            }
        }
        .task { loader.load(adUnitID: adUnitID) }
    }
}

/// 배너 광고 로드 + 생명주기 관리.
@MainActor
@Observable
private final class BannerAdLoader: NSObject, BannerViewDelegate {
    let bannerView: BannerView
    private(set) var didLoad = false
    private(set) var didFail = false
    private var hasStartedLoading = false

    override init() {
        bannerView = BannerView(adSize: AdSizeBanner)
        super.init()
        bannerView.delegate = self
    }

    func load(adUnitID: String) {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true

        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.boatRootViewController
        bannerView.load(Request())
    }

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        didLoad = true
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        CrashReporter.record(error)
        didFail = true
    }
}

/// 이미 로드된 BannerView 인스턴스를 그대로 표시하는 브릿지(재생성하지 않음).
private struct BannerContainerView: UIViewRepresentable {
    let bannerView: BannerView

    func makeUIView(context: Context) -> BannerView { bannerView }
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

#Preview {
    BoatBannerAdView()
        .padding(.horizontal, 20)
}
