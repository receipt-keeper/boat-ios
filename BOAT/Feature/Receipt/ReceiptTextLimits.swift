//
//  ReceiptTextLimits.swift
//  BOAT
//
//  영수증 입력/수정 화면에서 공유하는 텍스트 길이 제한과 편의 바인딩.
//

import SwiftUI

enum ReceiptTextLimits {
    static let productName = 50
    static let memo = 100
    static let brand = 50
    static let serial = 50
    static let warrantyMonths = 4
}

extension Binding where Value == String {
    /// 문자열 입력이 limit을 넘지 못하도록 강제로 잘라낸다.
    func limited(to limit: Int) -> Binding<String> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = String($0.prefix(limit)) }
        )
    }
}
