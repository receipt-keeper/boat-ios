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

            if showDebugPanel {
                Spacer().frame(height: .spacing20)
                debugServerPanel
                Spacer().frame(height: .spacing20)
            } else {
                Spacer().frame(height: 64)
            }
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

    // MARK: - [DEBUG/TestFlight] 서버 URL 전환 패널

    /// Debug 빌드 또는 TestFlight(sandboxReceipt) 환경에서만 노출
    private var showDebugPanel: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    private var debugServerPanel: some View {
        VStack(spacing: .spacing8) {
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

            Button {
                Task {
                    do {
                        try await APIClient.shared.requestVoid(ExampleTarget.serverError)
                    } catch {
                        let message = (error as? APIError).flatMap {
                            if case .server(_, let msg) = $0 { return msg } else { return nil }
                        } ?? String(localized: "error.api.unknown")
                        toast.showError(message)
                    }
                }
            } label: {
                Text("서버 에러 테스트")
                    .font(.pretendard(.medium, size: 13))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: .roundedMd)
                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
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
