//
//  LoginView.swift
//  BOAT
//
//  Android LoginScreen.kt 와 동일 레이아웃.
//

import SwiftUI

struct LoginView: View {

    var onAuthenticated: ((SocialUserInfo) -> Void)? = nil

    @State private var viewModel = AuthViewModel()
    @State private var toast = BoatToastState()

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            logoPlaceholder

            Spacer().frame(height: .spacing16)

            Text("login.subtitle")
                .font(.body2)
                .foregroundStyle(Color.gray500)

            Spacer()

            illustration

            Spacer()

            googleButton

            Spacer().frame(height: .spacing12)

            appleButton

            Spacer().frame(height: 64)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, .spacing20)
        .background(Color.colorWhite)
        .disabled(isLoading)
        .boatToastHost(toast)
        .onChange(of: viewModel.state) { _, newState in
            switch newState {
            case .authenticated(let userInfo):
                onAuthenticated?(userInfo)
            case .error(let message):
                toast.showError(message)
            default:
                break
            }
        }
    }

    // MARK: - 로고 (미정 — 임시 플레이스홀더)

    private var logoPlaceholder: some View {
        Text("login.logo_tbd")
            .font(.pretendard(.semibold, size: 16))
            .foregroundStyle(Color.colorWhite)
            .frame(width: 140, height: 52)
            .background(Color.brandPrimary, in: RoundedRectangle(cornerRadius: .roundedXl))
    }

    // MARK: - 일러스트 (TODO: 보트 일러스트 에셋으로 교체)

    private var illustration: some View {
        Image(systemName: "sailboat.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 174, height: 174)
            .foregroundStyle(Color.brandPrimary)
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
    LoginView()
}
