//
//  String+Utils.swift
//  BOAT
//

import Foundation

extension String {

    var containsURL: Bool {
        !detectedURLs.isEmpty
    }

    var firstURL: URL? {
        detectedURLs.first
    }

    /// 문자열 내 모든 URL을 감지해 반환합니다.
    var detectedURLs: [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let range = NSRange(startIndex..., in: self)
        return detector.matches(in: self, options: [], range: range).compactMap(\.url)
    }

    /// 문자열이 유효한 URL 형식인지 확인합니다.
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}
