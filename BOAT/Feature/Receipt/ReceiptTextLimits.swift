//
//  ReceiptTextLimits.swift
//  BOAT
//
//  영수증 입력/수정 화면에서 공유하는 텍스트 길이 제한.
//

enum ReceiptTextLimits {
    static let productName = 50
    static let memo = 100
    static let brand = 50
    static let serial = 50
    static let warrantyMonths = 4
    /// 구매 가격 상한 — 이 값 이상은 등록할 수 없다(999,999,999원 이상 제한).
    /// 자릿수가 아니라 금액 자체로 판단하므로 123,456,789 같은 9자리 값은 정상 통과한다.
    static let priceMax = 999_999_999
    /// 가격 입력 필드 최대 자릿수 (상한 금액의 자릿수와 동일)
    static let priceDigits = 9
}
