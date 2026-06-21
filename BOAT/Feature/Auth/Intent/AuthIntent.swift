//
//  AuthIntent.swift
//  BOAT
//

enum AuthIntent {
    case signInWithGoogle
    case signInWithApple
    /// 약관 동의 완료 → 백엔드 로그인 (신규 가입)
    case completeTerms(terms: Bool, privacy: Bool, marketing: Bool)
    case signOut
}
