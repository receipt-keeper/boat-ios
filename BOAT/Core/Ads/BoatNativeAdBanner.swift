//
//  BoatNativeAdBanner.swift
//  BOAT
//
//  기존 AccessoryBanner 디자인을 계승하는 구글 네이티브 광고 컴포넌트.
//  Android BoatNativeAd.kt 대응 — 헤드라인/본문 + 메인 이미지·동영상(MediaView)을 노출하고
//  (CTA 버튼 없음), 광고 로드 실패 시 기존 AccessoryBanner로 폴백한다.
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

/// UIKit NativeAdView를 감싸는 브릿지. headline/body + 메인 이미지·동영상(MediaView)을 매핑한다
/// (CTA 버튼 없음). 우측 시각 요소는 아이콘 전용 ImageView가 아니라 MediaView를 써야 한다 —
/// AdMob Native Ad Validator가 "MediaView not used for main image or video asset"로 지적한 부분.
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

        let mediaView = MediaView()
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 8
        mediaView.translatesAutoresizingMaskIntoConstraints = false

        // 필수 표시 요소: "Ad" 뱃지 (Android 레이아웃과 동일한 반투명 검정 배경)
        let adBadge = UILabel()
        adBadge.text = "Ad"
        adBadge.font = .systemFont(ofSize: 10)
        adBadge.textColor = .white
        adBadge.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        adBadge.textAlignment = .center
        adBadge.translatesAutoresizingMaskIntoConstraints = false

        // AdChoices(광고 선택 옵션) 아이콘 — Google이 명시적으로 요구하는 필수 표시 요소.
        // 설정하지 않으면 SDK가 기본 위치(우상단)에 자체적으로 얹지만, 우리 커스텀 레이아웃의
        // 다른 요소와 겹칠 수 있어 직접 자리를 잡아준다. nativeAd 설정보다 먼저 지정해야 한다.
        let adChoicesView = AdChoicesView()
        adChoicesView.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(textStack)
        adView.addSubview(mediaView)
        adView.addSubview(adBadge)
        adView.addSubview(adChoicesView)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 24),
            textStack.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: mediaView.leadingAnchor, constant: -12),

            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -24),
            mediaView.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            mediaView.widthAnchor.constraint(equalToConstant: 100),
            mediaView.heightAnchor.constraint(equalToConstant: 100),

            adBadge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 4),
            adBadge.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 4),
            adBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 22),
            adBadge.heightAnchor.constraint(equalToConstant: 14),

            adChoicesView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 4),
            adChoicesView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -4),
            adChoicesView.widthAnchor.constraint(equalToConstant: 20),
            adChoicesView.heightAnchor.constraint(equalToConstant: 20),
        ])

        adView.headlineView = headlineLabel
        adView.bodyView = bodyLabel
        adView.mediaView = mediaView
        adView.adChoicesView = adChoicesView

        return adView
    }

    func updateUIView(_ adView: NativeAdView, context: Context) {
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        (adView.mediaView as? MediaView)?.mediaContent = nativeAd.mediaContent
        adView.nativeAd = nativeAd
    }
}

#Preview {
    BoatNativeAdBanner()
        .padding(.horizontal, 20)
}
