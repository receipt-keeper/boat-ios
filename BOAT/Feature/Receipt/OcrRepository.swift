//
//  OcrRepository.swift
//  BOAT
//
//  영수증 OCR 분석. POST /api/v1/ocr — 이미지를 multipart로 전송, 저장 없이 분석 결과만 수신.
//

import UIKit
import Alamofire

@MainActor
final class OcrRepository {
    static let shared = OcrRepository()
    private init() {}

    /// POST /api/v1/ocr — 등록한 영수증 이미지를 multipart(`file`)로 전송하고 분석 결과를 반환.
    func analyze(_ images: [UIImage]) async throws -> OcrAnalysis {
        try await APIClient.shared.uploadMultipart(
            path: "/api/v1/ocr",
            builder: { form in
                for (index, image) in images.enumerated() {
                    guard let data = image.jpegData(compressionQuality: 0.9) else { continue }
                    form.append(
                        data,
                        withName: "file",
                        fileName: "receipt-\(index + 1).jpg",
                        mimeType: "image/jpeg"
                    )
                }
            }
        )
    }
}
