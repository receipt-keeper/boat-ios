//
//  ReceiptParser.swift
//  BOAT
//

import Foundation

struct ReceiptParser {

    static func parse(lines: [String]) -> ParsedReceipt {
        let brandName    = extractBrand(from: lines)
        let productName  = extractProductName(from: lines, brand: brandName)
        let purchaseDate = extractDate(from: lines)
        let warranty     = extractWarrantyMonths(from: lines)
        let price        = extractPrice(from: lines)
        let serial       = extractSerialNumber(from: lines)
        let category     = inferCategory(from: productName)

        return ParsedReceipt(
            productName:    productName,
            purchaseDate:   purchaseDate,
            warrantyMonths: warranty,
            brandName:      brandName,
            price:          price,
            serialNumber:   serial,
            category:       category
        )
    }
}

// MARK: - 구매일

private extension ReceiptParser {

    static func extractDate(from lines: [String]) -> Date? {
        // 지원 패턴: 2024.06.18 / 2024/06/18 / 2024-06-18 / 2024년 6월 18일 / 24.06.18
        let patterns = [
            #"(\d{4})[.\-/](\d{1,2})[.\-/](\d{1,2})"#,
            #"(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일"#,
            #"(\d{2})[.\-/](\d{2})[.\-/](\d{2})"#,
        ]

        for line in lines {
            for pattern in patterns {
                if let date = parseDate(from: line, pattern: pattern), date <= Date() {
                    return date
                }
            }
        }
        return nil
    }

    static func parseDate(from text: String, pattern: String) -> Date? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 4 else { return nil }

        let groups = (1...3).compactMap { i -> Int? in
            guard let range = Range(match.range(at: i), in: text) else { return nil }
            return Int(text[range])
        }
        guard groups.count == 3 else { return nil }

        var components = DateComponents()
        components.year  = groups[0] < 100 ? 2000 + groups[0] : groups[0]
        components.month = groups[1]
        components.day   = groups[2]
        return Calendar.current.date(from: components)
    }
}

// MARK: - 무상 AS 기간

private extension ReceiptParser {

    static func extractWarrantyMonths(from lines: [String]) -> Int? {
        let keywords = ["보증기간", "품질보증", "무상보증", "warranty", "보증"]

        for line in lines {
            let lower = line.lowercased()
            guard keywords.contains(where: { lower.contains($0) }) else { continue }

            // "2년" → 24개월
            if let regex = try? NSRegularExpression(pattern: #"(\d+)\s*년"#),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let range = Range(match.range(at: 1), in: line),
               let years = Int(line[range]) {
                let months = years * 12
                if (1...60).contains(months) { return months }
            }

            // "12개월"
            if let regex = try? NSRegularExpression(pattern: #"(\d+)\s*개월"#),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let range = Range(match.range(at: 1), in: line),
               let months = Int(line[range]) {
                if (1...60).contains(months) { return months }
            }
        }
        return nil
    }
}

// MARK: - 가격

private extension ReceiptParser {

    static func extractPrice(from lines: [String]) -> Int? {
        let priceKeywords = ["합계", "총액", "결제금액", "판매가", "price", "total", "금액", "₩"]
        let pricePattern  = #"([\d,]+)\s*원?"#

        // 키워드가 포함된 줄에서 우선 추출
        for line in lines {
            let lower = line.lowercased()
            guard priceKeywords.contains(where: { lower.contains($0) }) else { continue }
            if let price = largestNumber(in: line, pattern: pricePattern), price > 0 { return price }
        }

        // 원 단위 표기가 있는 줄에서 추출 (최대값 선택)
        return lines
            .compactMap { largestNumber(in: $0, pattern: pricePattern) }
            .filter { $0 > 0 }
            .max()
    }

    static func largestNumber(in text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match -> Int? in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return Int(text[range].replacingOccurrences(of: ",", with: ""))
        }.max()
    }
}

// MARK: - 시리얼 넘버

private extension ReceiptParser {

    static func extractSerialNumber(from lines: [String]) -> String? {
        let keywords = ["s/n", "serial", "시리얼", "일련번호", "s.n"]

        for line in lines {
            let lower = line.lowercased()
            guard keywords.contains(where: { lower.contains($0) }) else { continue }

            let parts = line.components(separatedBy: CharacterSet(charactersIn: ":："))
            if parts.count >= 2 {
                let value = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { return value }
            }
        }
        return nil
    }
}

// MARK: - 브랜드

private extension ReceiptParser {

    static let knownBrands = [
        "삼성", "LG", "애플", "Apple", "소니", "Sony", "다이슨", "Dyson",
        "필립스", "Philips", "쿠쿠", "쿠첸", "위닉스", "청호", "코웨이",
        "캐리어", "하이얼", "파나소닉", "보쉬", "밀레", "일렉트로룩스",
        "샤오미", "로보락", "에코백스", "드롱기", "아이로봇",
        "보스", "Bose", "JBL", "야마하", "Yamaha", "젠하이저", "현대", "대우"
    ]

    static func extractBrand(from lines: [String]) -> String? {
        let brandKeywords = ["제조사", "브랜드", "brand", "manufacturer"]

        // 키워드 기반
        for line in lines {
            let lower = line.lowercased()
            if brandKeywords.contains(where: { lower.contains($0) }) {
                let parts = line.components(separatedBy: CharacterSet(charactersIn: ":："))
                if parts.count >= 2 {
                    let value = parts.dropFirst().joined().trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty { return value }
                }
            }
        }

        // 알려진 브랜드 매칭
        let fullText = lines.joined(separator: " ")
        return knownBrands.first { fullText.localizedCaseInsensitiveContains($0) }
    }
}

// MARK: - 제품명

private extension ReceiptParser {

    static let productNameKeywords = ["상품명", "품명", "제품명", "모델명", "모델", "model", "item"]

    // 날짜·가격·노이즈 줄 필터링용
    static let noisePatterns: [NSRegularExpression] = [
        #"\d{4}[.\-/]\d{2}"#,  // 날짜
        #"[\d,]+\s*원"#,        // 가격
        #"^\s*(tel|전화|주소|사업자|대표|영수증|receipt)\b"#,
    ].compactMap { try? NSRegularExpression(pattern: $0, options: .caseInsensitive) }

    static func extractProductName(from lines: [String], brand: String?) -> String? {
        // 키워드 다음 값 추출
        for line in lines {
            let lower = line.lowercased()
            if productNameKeywords.contains(where: { lower.contains($0) }) {
                let parts = line.components(separatedBy: CharacterSet(charactersIn: ":："))
                if parts.count >= 2 {
                    let value = parts.dropFirst().joined().trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty { return String(value.prefix(30)) }
                }
            }
        }

        // 브랜드명이 포함된 줄
        if let brand, let line = lines.first(where: { $0.localizedCaseInsensitiveContains(brand) }) {
            return String(line.trimmingCharacters(in: .whitespaces).prefix(30))
        }

        // 노이즈 아닌 첫 번째 유효 줄
        return lines.first { line in
            let range = NSRange(line.startIndex..., in: line)
            return line.count >= 2 && !noisePatterns.contains { $0.firstMatch(in: line, range: range) != nil }
        }.map { String($0.prefix(30)) }
    }
}

// MARK: - 대분류

private extension ReceiptParser {

    static func inferCategory(from productName: String?) -> DeviceCategory {
        guard let name = productName else { return .other }
        for category in DeviceCategory.allCases where category != .other {
            if category.keywords.contains(where: { name.localizedCaseInsensitiveContains($0) }) {
                return category
            }
        }
        return .other
    }
}
