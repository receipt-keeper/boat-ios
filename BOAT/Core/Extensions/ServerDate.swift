//
//  ServerDate.swift
//  BOAT
//
//  서버가 내려주는 시각 문자열(UTC)을 Date로 파싱하는 공용 유틸.
//  서버는 포맷이 케이스마다 조금씩 다르다:
//   - "2026-07-10T13:06:44.805Z" (소수초 + Z)   ← 실제 대부분의 타임스탬프
//   - "2026-06-29T12:00:00Z"     (Z만)
//   - "2026-06-29T12:00:00"      (타임존 표기 없음 — UTC로 간주)
//  Swift의 DateFormatter/ISO8601DateFormatter는 하나로 세 케이스를 다 못 잡고,
//  (Android의 SimpleDateFormat과 달리) 뒤에 남는 문자를 관대하게 무시하지도 않는다.
//  그래서 여러 파서를 순서대로 시도한다.
//

import Foundation

enum ServerDate {

    private static let iso8601WithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// 타임존 표기가 없는 "yyyy-MM-dd'T'HH:mm:ss" 를 UTC로 해석하는 폴백.
    private static let plainUTC: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    /// 서버 시각 문자열 → Date. 파싱 실패 시 nil.
    static func parse(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return iso8601WithFraction.date(from: raw)
            ?? iso8601.date(from: raw)
            ?? plainUTC.date(from: raw)
    }
}
