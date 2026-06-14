//
//  BaseURL.swift
//  BOAT
//
//  서버 Base URL을 한 곳에서 관리합니다.
//  추후 개발/운영 환경 분리가 필요하면 빌드 컨피그(DEBUG)로 분기하세요.
//

import Foundation

enum BaseURL {
    /// TODO: 실제 BOAT 백엔드 주소로 교체
    static let current = URL(string: "https://api.boat.receipt-keeper.com")!
}
