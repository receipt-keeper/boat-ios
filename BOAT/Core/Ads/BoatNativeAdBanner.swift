//
//  BoatNativeAdBanner.swift
//  BOAT
//
//  기존 AccessoryBanner 디자인을 계승하는 구글 네이티브 광고 컴포넌트.
//  Android BoatNativeAd.kt 대응 — 동일하게 헤드라인/본문/아이콘만 노출하고
//  (미디어뷰·CTA 버튼 없음), 광고 로드 실패 시 기존 AccessoryBanner로 폴백한다.
//

import GoogleMobileAds
import SwiftUI

struct BoatNativeAdBanner: View {
    var adUnitID: String = AdsConfig.nativeAdUnitID

    @State private var loader = NativeAdBannerLoader()

    var body: some View {
        Group {
            if let nativeAd = loader.nativeAd {
                NativeAdContainerView(nativeAd: nativeAd)
                    .frame(height: 110)
            } else if loader.didFail {
                // 광고 로드 실패 시 기존 임시 배너로 폴백 (Android 동일)
                AccessoryBanner()
            } else {
                Color.clear.frame(height: 110)
            }
        }
        .task { loader.load(adUnitID: adUnitID) }
    }
}

/// 네이티브 광고 로드 + 생명주기 관리. Android DisposableEffect(AdLoader)/onDispose 대응.
@MainActor
@Observable
private final class NativeAdBannerLoader: NSObject, NativeAdLoaderDelegate {
    private(set) var nativeAd: NativeAd?
    private(set) var didFail = false

    private var adLoader: AdLoader?
    private var hasStartedLoading = false

    func load(adUnitID: String) {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true

        let loader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: UIApplication.boatRootViewController,
            adTypes: [.native],
            options: nil
        )
        loader.delegate = self
        loader.load(Request())
        adLoader = loader
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        CrashReporter.record(error)
        didFail = true
    }
}

/// UIKit NativeAdView를 감싸는 브릿지. Android populateNativeAdView와 동일하게
/// headline/body/icon만 매핑한다(미디어뷰·CTA 버튼 없음).
private struct NativeAdContainerView: UIViewRepresentable {
    let nativeAd: NativeAd

    private static let backgroundColor = UIColor(red: 0xE9 / 255, green: 0xF4 / 255, blue: 0xFF / 255, alpha: 1)
    private static let headlineColor = UIColor(red: 0x33 / 255, green: 0x33 / 255, blue: 0x33 / 255, alpha: 1)
    private static let bodyColor = UIColor(red: 0x77 / 255, green: 0x77 / 255, blue: 0x77 / 255, alpha: 1)

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = Self.backgroundColor
        adView.layer.cornerRadius = 12
        adView.clipsToBounds = true

        let headlineLabel = UILabel()
        headlineLabel.font = UIFont(name: "Pretendard-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        headlineLabel.textColor = Self.headlineColor
        headlineLabel.numberOfLines = 1

        let bodyLabel = UILabel()
        bodyLabel.font = UIFont(name: "Pretendard-Regular", size: 13) ?? .systemFont(ofSize: 13)
        bodyLabel.textColor = Self.bodyColor
        bodyLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [headlineLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // 필수 표시 요소: "Ad" 뱃지 (Android 레이아웃과 동일한 반투명 검정 배경)
        let adBadge = UILabel()
        adBadge.text = "Ad"
        adBadge.font = .systemFont(ofSize: 10)
        adBadge.textColor = .white
        adBadge.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        adBadge.textAlignment = .center
        adBadge.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(textStack)
        adView.addSubview(iconView)
        adView.addSubview(adBadge)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 24),
            textStack.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: iconView.leadingAnchor, constant: -12),

            iconView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -24),
            iconView.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 100),
            iconView.heightAnchor.constraint(equalToConstant: 100),

            adBadge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 4),
            adBadge.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 4),
            adBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 22),
            adBadge.heightAnchor.constraint(equalToConstant: 14),
        ])

        adView.headlineView = headlineLabel
        adView.bodyView = bodyLabel
        adView.iconView = iconView

        return adView
    }

    func updateUIView(_ adView: NativeAdView, context: Context) {
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        if let icon = nativeAd.icon {
            (adView.iconView as? UIImageView)?.image = icon.image
        }
        adView.nativeAd = nativeAd
    }
}

#Preview {
    BoatNativeAdBanner()
        .padding(.horizontal, 20)
}
