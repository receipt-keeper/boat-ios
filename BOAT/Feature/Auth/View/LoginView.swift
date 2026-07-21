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
            // 상단 여백:서브타이틀-버튼 사이 여백 비율 1:1.5 (Android weight(1f):weight(1.5f) 대응)
            Spacer()
            Spacer()

            logoSection

            Spacer()
            Spacer()
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

    // MARK: - 로고("Boat" 검정 + "Lab" 파랑 텍스트) + 서브타이틀

    private var logoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text("Boat ")
                    .font(.pretendard(.bold, size: 48))
                    .foregroundStyle(Color.gray900)
                Text("Lab")
                    .font(.pretendard(.bold, size: 48))
                    .foregroundStyle(Color.brandPrimary)
            }
            .frame(width: 210)

            Text("login.subtitle")
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color.gray700)
                .multilineTextAlignment(.center)
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
                    .foregroundStyle(Color.gray900)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .padding(.horizontal, .spacing16)
            .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
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
            .background(Color.black, in: RoundedRectangle(cornerRadius: .roundedLg))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
}
