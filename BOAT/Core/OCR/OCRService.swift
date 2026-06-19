//
//  OCRService.swift
//  BOAT
//

import Vision
import UIKit

struct RecognizedText {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

actor OCRService {

    static let shared = OCRService()

    private init() {}

    /// 이미지에서 텍스트를 인식하고 신뢰도 순으로 정렬해 반환합니다.
    func recognize(image: UIImage) async throws -> [RecognizedText] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.recognitionFailed(underlying: error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let results = observations.compactMap { observation -> RecognizedText? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return RecognizedText(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                .sorted { $0.confidence > $1.confidence }

                continuation.resume(returning: results)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: image.cgImageOrientation,
                options: [:]
            )

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(underlying: error))
            }
        }
    }

    /// 인식된 텍스트를 위에서 아래 순서(영수증 읽기 순)로 반환합니다.
    func recognizeOrdered(image: UIImage) async throws -> [String] {
        let results = try await recognize(image: image)

        return results
            .sorted { $0.boundingBox.minY > $1.boundingBox.minY }
            .map(\.text)
    }
}

// MARK: - UIImage Orientation

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:            return .up
        case .down:          return .down
        case .left:          return .left
        case .right:         return .right
        case .upMirrored:    return .upMirrored
        case .downMirrored:  return .downMirrored
        case .leftMirrored:  return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default:    return .up
        }
    }
}
