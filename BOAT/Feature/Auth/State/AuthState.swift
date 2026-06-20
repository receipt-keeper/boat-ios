//
//  AuthState.swift
//  BOAT
//

enum AuthState: Equatable {
    case idle
    case loading
    case authenticated(SocialUserInfo)
    case unauthenticated
    case error(String)
}
