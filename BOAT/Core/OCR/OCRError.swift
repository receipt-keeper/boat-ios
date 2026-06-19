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
            return "유효하지 않은 이미지입니다."
        case .recognitionFailed(let error):
            return "텍스트 인식에 실패했습니다: \(error.localizedDescription)"
        case .noTextFound:
            return "이미지에서 텍스트를 찾을 수 없습니다."
        }
    }
}
