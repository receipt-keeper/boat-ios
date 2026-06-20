//
//  AuthIntent.swift
//  BOAT
//

import AuthenticationServices

enum AuthIntent {
    case signInWithGoogle
    case signInWithApple(Result<ASAuthorization, Error>)
    case signOut
}
