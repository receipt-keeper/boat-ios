//
//  ReceiptChangeBus.swift
//  BOAT
//
//  영수증 생성/수정/삭제가 있을 때마다 버전을 올리는 공용 이벤트 버스.
//  홈 대시보드/목록 탭처럼 영수증 리스트를 들고 있는 화면들은 이 값을 관찰해
//  자신을 직접 변경하지 않은 다른 화면에서 일어난 등록/수정/삭제 후에도
//  항상 최신 데이터로 재조회한다. ReceiptRepository의 mutating 메서드가 호출한다.
//

import Foundation

@MainActor
@Observable
final class ReceiptChangeBus {
    static let shared = ReceiptChangeBus()
    private init() {}

    private(set) var version = 0

    func notifyChanged() {
        version += 1
    }
}
