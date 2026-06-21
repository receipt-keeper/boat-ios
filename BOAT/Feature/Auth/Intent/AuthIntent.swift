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
    /// 회원 탈퇴 — 서버 계정 삭제 후 로컬 정리
    case deleteAccount
}
