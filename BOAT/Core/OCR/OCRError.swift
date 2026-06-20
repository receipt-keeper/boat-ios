//
//  OCRError.swift
//  BOAT
//

import Foundation

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(underlying: Error)
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return String(localized: "error.ocr.invalid_image")
        case .recognitionFailed(let error):
            return String(localized: "error.ocr.recognition_failed \(error.localizedDescription)")
        case .noTextFound:
            return String(localized: "error.ocr.no_text_found")
        }
    }
}
