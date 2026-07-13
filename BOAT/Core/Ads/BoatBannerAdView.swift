//
//  BoatBannerAdView.swift
//  BOAT
//
//  구글 표준 배너 광고. 네이티브 광고 대신 배너 형식으로 전환.
//  고정 크기(320x50) 배너는 카드 폭을 다 못 채워 기존 AccessoryBanner의 둥근 테두리 카드
//  형태를 유지할 수 없었다 — 화면 폭에 맞춰 채워지는 적응형(Adaptive) 배너로 로드하고,
//  기존과 동일한 둥근 모서리 + 연한 파란 배경 카드 안에 담아 형태를 그대로 유지한다.
//  로드 실패 시 기존 AccessoryBanner로 폴백한다.
//

import GoogleMobileAds
import SwiftUI

struct BoatBannerAdView: View {
    var adUnitID: String = AdsConfig.bannerAdUnitID

    @State private var loader = BannerAdLoader()

    /// 기존 AccessoryBanner/네이티브 광고 카드와 동일한 카드 높이.
    private static let cardHeight: CGFloat = 110

    var body: some View {
        GeometryReader { geo in
            Group {
                if loader.didLoad {
                    BannerContainerView(bannerView: loader.bannerView)
                } else if loader.didFail {
                    // 광고 로드 실패 시 기존 임시 배너로 폴백 (Android 동일)
                    AccessoryBanner()
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#E9F4FF"))
            .clipShape(RoundedRectangle(cornerRadius: .roundedXl))
            .task {
                loader.load(adUnitID: adUnitID, width: geo.size.width)
            }
        }
        .frame(height: Self.cardHeight)
    }
}

/// 배너 광고 로드 + 생명주기 관리.
@MainActor
@Observable
private final class BannerAdLoader: NSObject, BannerViewDelegate {
    // 실제 폭은 load(adUnitID:width:)에서 확정되기 전까지 임시로 표준 배너 크기를 준다.
    let bannerView = BannerView(adSize: AdSizeBanner)
    private(set) var didLoad = false
    private(set) var didFail = false
    private var hasStartedLoading = false

    override init() {
        super.init()
        bannerView.delegate = self
    }

    /// width에 맞춰 화면 폭을 채우는 적응형 배너 크기로 로드한다.
    func load(adUnitID: String, width: CGFloat) {
        guard !hasStartedLoading, width > 0 else { return }
        hasStartedLoading = true

        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
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
