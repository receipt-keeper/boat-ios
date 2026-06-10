//
//  LoginView.swift
//  BOAT
//

import SwiftUI
import GoogleSignInSwift

struct LoginView: View {

    var onAuthenticated: (() -> Void)? = nil

    @State private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // 로고 영역 (추후 에셋 적용)
            Text("BOAT")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            // 구글 로그인 버튼
            GoogleSignInButton(action: {
                viewModel.dispatch(.signInWithGoogle)
            })
            .frame(height: 50)
            .padding(.horizontal, 24)

            // 에러 메시지
            if case .error(let message) = viewModel.state {
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            // 로딩
            if case .loading = viewModel.state {
                ProgressView()
            }
        }
        .padding(.bottom, 48)
        .onChange(of: viewModel.state) { _, newState in
            if case .authenticated = newState {
                onAuthenticated?()
            }
        }
    }
}

#Preview {
    LoginView()
}
