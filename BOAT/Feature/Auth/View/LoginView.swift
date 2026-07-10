//
//  LoginView.swift
//  BOAT
//
//  Android LoginScreen.kt 와 동일 레이아웃.
//

import SwiftUI

struct LoginView: View {

    let viewModel: AuthViewModel

    @State private var toast = BoatToastState()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            logoSection

            Spacer()

            googleButton

            Spacer().frame(height: .spacing12)

            appleButton

            Spacer().frame(height: 64)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, .spacing20)
        .background(Color.colorWhite)
        .disabled(viewModel.isLoading)
        .boatToastHost(toast)
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toast.showError(message)
                viewModel.errorMessage = nil
            }
        }
    }

    // MARK: - 로고 + 서브타이틀

    private var logoSection: some View {
        VStack(spacing: .spacing16) {
            Image("app_logo_text")
                .resizable()
                .scaledToFit()
                .frame(height: 56)

            Text("login.subtitle")
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.gray500)
        }
    }

    // MARK: - Google 버튼 (흰 배경 + 파란 테두리)

    private var googleButton: some View {
        Button {
            viewModel.dispatch(.signInWithGoogle)
        } label: {
            ZStack {
                HStack {
                    Image("icGoogle")
                        .frame(width: 20, height: 20)
                    Spacer()
                }
                Text("login.button.google")
                    .font(.pretendard(.medium, size: 15))
                    .foregroundStyle(Color(hex: "#3C3C3C"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .padding(.horizontal, .spacing16)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedXl)
                    .stroke(Color.brandPrimary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Apple 버튼 (검정 배경)

    private var appleButton: some View {
        Button {
            viewModel.dispatch(.signInWithApple)
        } label: {
            ZStack {
                HStack {
                    Image("icApple")
                        .renderingMode(.template)
                        .foregroundStyle(Color.colorWhite)
                        .frame(width: 20, height: 20)
                    Spacer()
                }
                Text("login.button.apple")
                    .font(.pretendard(.medium, size: 15))
                    .foregroundStyle(Color.colorWhite)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .padding(.horizontal, .spacing16)
            .background(Color.black, in: RoundedRectangle(cornerRadius: .roundedXl))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
}
