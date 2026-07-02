//
//  Int+Utils.swift
//  BOAT
//

import Foundation

extension Int {

    /// 천 단위 콤마 포맷. 앱 내 모든 가격/금액 표시는 이 프로퍼티를 거쳐야 한다.
    /// 예: 434000 → "434,000"
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
