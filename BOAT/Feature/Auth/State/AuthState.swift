//
//  AuthState.swift
//  BOAT
//

enum AuthState: Equatable {
    case idle
    case loading
    case authenticated
    case unauthenticated
    case error(String)
}
