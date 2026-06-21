//
//  TermsView.swift
//  BOAT
//
//  Android TermsScreen.kt 와 동일 레이아웃 (회원가입 약관 동의).
//  소셜 로그인 성공 후 진입 → 동의 완료 시 백엔드 로그인 호출.
//

import SwiftUI

struct TermsView: View {

    let viewModel: AuthViewModel

    @State private var ageConsent    = false
    @State private var serviceTerms  = false
    @State private var privacyPolicy = false
    @State private var marketing     = false
    @State private var toast = BoatToastState()

    private var allAgreed: Bool { ageConsent && serviceTerms && privacyPolicy && marketing }
    private var allRequired: Bool { ageConsent && serviceTerms && privacyPolicy }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: .spacing4)

                Text("terms.headline")
                    .font(.pretendard(.bold, size: 22))
                    .foregroundStyle(Color.gray900)
                    .lineSpacing(6)

                Spacer().frame(height: .spacing32)

                agreeAllRow

                Spacer().frame(height: .spacing8)

                termsItem("terms.age", checked: $ageConsent, showView: false)
                termsItem("terms.service", checked: $serviceTerms, showView: true)
                termsItem("terms.privacy", checked: $privacyPolicy, showView: true)
                termsItem("terms.marketing", checked: $marketing, showView: true)

                Spacer()

                completeButton

                Spacer().frame(height: .spacing16)
            }
            .padding(.horizontal, .spacing20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        .boatToastHost(toast)
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toast.showError(message)
                viewModel.errorMessage = nil
            }
        }
    }

    // MARK: - Top Bar (뒤로가기 + 회원가입)

    private var topBar: some View {
        ZStack {
            Text("terms.title")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(Color.gray900)

            HStack {
                Button {
                    // 약관 단계에서 뒤로 → 소셜 세션 정리하고 로그인 화면 복귀
                    viewModel.dispatch(.signOut)
                } label: {
                    Image("icChevronLeft")
                        .renderingMode(.template)
                        .foregroundStyle(Color.gray900)
                        .frame(width: 24, height: 24)
                }
                Spacer()
            }
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    // MARK: - 전체 동의

    private var agreeAllRow: some View {
        Button {
            let next = !allAgreed
            ageConsent = next
            serviceTerms = next
            privacyPolicy = next
            marketing = next
        } label: {
            HStack(spacing: .spacing12) {
                checkIcon(allAgreed)
                Text("terms.agree_all")
                    .font(.pretendard(.semibold, size: 15))
                    .foregroundStyle(Color.gray900)
                Spacer()
            }
            .padding(.horizontal, .spacing16)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                allAgreed ? Color.brandSenary : Color.gray100,
                in: RoundedRectangle(cornerRadius: .roundedLg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .roundedLg)
                    .stroke(Color.brandTertiary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 개별 약관 항목

    private func termsItem(
        _ titleKey: LocalizedStringKey,
        checked: Binding<Bool>,
        showView: Bool
    ) -> some View {
        Button {
            checked.wrappedValue.toggle()
        } label: {
            HStack(spacing: .spacing12) {
                checkIcon(checked.wrappedValue)
                Text(titleKey)
                    .font(.body2)
                    .foregroundStyle(Color.gray700)
                Spacer()
                if showView {
                    Text("terms.view")
                        .font(.pretendard(.regular, size: 13))
                        .foregroundStyle(Color.gray500)
                }
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func checkIcon(_ checked: Bool) -> some View {
        Image("icCheck")
            .renderingMode(.template)
            .foregroundStyle(checked ? Color.brandPrimary : Color.gray400)
            .frame(width: 20, height: 20)
    }

    // MARK: - 선택 완료

    private var completeButton: some View {
        Button {
            viewModel.dispatch(.completeTerms(
                terms: serviceTerms,
                privacy: privacyPolicy,
                marketing: marketing
            ))
        } label: {
            Text("terms.complete")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(allRequired ? Color.colorWhite : Color.gray500)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    allRequired ? Color.brandPrimary : Color.gray200,
                    in: RoundedRectangle(cornerRadius: .roundedXl)
                )
        }
        .buttonStyle(.plain)
        .disabled(!allRequired || viewModel.isLoading)
    }
}

#Preview {
    TermsView(viewModel: AuthViewModel())
}
