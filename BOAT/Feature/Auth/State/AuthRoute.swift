//
//  AuthRoute.swift
//  BOAT
//
//  인증 플로우의 화면 라우팅 상태.
//  로딩/에러 같은 전환 상태는 AuthViewModel의 isLoading/errorMessage로 분리한다.
//

enum AuthRoute: Equatable {
    /// 로그인 화면 (미인증)
    case login
    /// 소셜 로그인 성공 → 약관 동의 대기
    case terms
    /// 백엔드 토큰 보유 (로그인 완료)
    case home
}
