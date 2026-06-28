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

            #if DEBUG
            Spacer().frame(height: .spacing20)
            debugServerPanel
            Spacer().frame(height: .spacing20)
            #else
            Spacer().frame(height: 64)
            #endif
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

    // MARK: - [DEBUG] 서버 URL 전환 패널

    #if DEBUG
    private var debugServerPanel: some View {
        HStack(spacing: .spacing12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DEBUG")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.colorWhite)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 3))

                Text(DebugConfig.shared.useLocalServer
                     ? "localhost:8000"
                     : "boatlab-dev.luigi99.cloud")
                    .font(.system(size: 12))
                    .foregroundStyle(DebugConfig.shared.useLocalServer ? Color.red : Color.gray500)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Text("로컬 서버")
                .font(.pretendard(.medium, size: 13))
                .foregroundStyle(Color.gray600)

            Toggle("", isOn: Binding(
                get: { DebugConfig.shared.useLocalServer },
                set: { DebugConfig.shared.useLocalServer = $0 }
            ))
            .labelsHidden()
            .tint(Color.red)
        }
        .padding(.horizontal, .spacing16)
        .padding(.vertical, .spacing12)
        .background(
            RoundedRectangle(cornerRadius: .roundedLg)
                .stroke(Color.red.opacity(0.35), lineWidth: 1)
        )
        .background(
            Color.red.opacity(0.04),
            in: RoundedRectangle(cornerRadius: .roundedLg)
        )
    }
    #endif

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
