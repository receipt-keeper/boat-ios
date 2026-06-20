//
//  SocialUserInfo.swift
//  BOAT
//

struct SocialUserInfo: Equatable {

    enum Provider: Equatable {
        case google
        case apple
    }

    let email: String?
    let name: String?
    let provider: Provider
}
