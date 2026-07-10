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
}
