//
//  GifImageView.swift
//  BOAT
//
//  번들 내 GIF 파일을 ImageIO로 읽어 UIImageView에서 무한 재생.
//  파일이 없으면 빈 뷰로 대체됨.
//

import SwiftUI
import UIKit
import ImageIO

struct GifImageView: UIViewRepresentable {

    /// 확장자(.gif) 제외한 파일명
    let name: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true
        // UIImageView의 intrinsic content size(GIF 원본 픽셀)가 SwiftUI .frame()을 무시하고
        // 원본 크기로 렌더되지 않도록, 오토레이아웃 우선순위를 낮춰 프레임에 맞춰 축소되게 한다.
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return imageView
        }

        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var totalDuration: TimeInterval = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any]
            let gifProps = props?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
            let delay = gifProps?[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval
                ?? gifProps?[kCGImagePropertyGIFDelayTime as String] as? TimeInterval
                ?? 0.1
            totalDuration += max(delay, 0.01)
            frames.append(UIImage(cgImage: cgImage))
        }

        imageView.animationImages = frames
        imageView.animationDuration = totalDuration
        imageView.animationRepeatCount = 0  // 무한 반복
        imageView.startAnimating()
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    /// SwiftUI가 제안한 크기를 그대로 채택해, UIImageView가 원본 GIF 크기(intrinsic)로
    /// 커지지 않고 호출부의 .frame() 안에 정확히 들어가도록 한다.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        guard let width = proposal.width, let height = proposal.height,
              width != .infinity, height != .infinity else {
            return nil
        }
        return CGSize(width: width, height: height)
    }
}
