//
//  MarketingConsentView.swift
//  BOAT
//
//  마케팅 정보 수신동의 전문 화면. 회원가입(TermsView)의 "마케팅 정보 수신 동의 보기" 탭에서
//  진입한다. TermsOfServiceView/PrivacyPolicyView와 동일한 타이포그래피로 구성.
//

import SwiftUI

struct MarketingConsentView: View {

    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                content
                    .padding(.horizontal, .spacing20)
                    .padding(.top, .spacing8)
                    .padding(.bottom, .spacing32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            Text("marketing_consent.title")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(Color.gray900)
            HStack {
                Button(action: onBack) {
                    Image("icChevronLeft")
                        .renderingMode(.template)
                        .foregroundStyle(Color.gray900)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: .spacing24) {
            pageTitle("[선택] 마케팅 정보 수신 동의")

            paragraph("보트랩 서비스는 사용자에게 더 유용한 혜택과 서비스 소식을 전해드리기 위해 아래와 같이 마케팅 정보를 수집·활용하며, 이에 대해 선택적 동의를 받습니다.")

            sectionHeader("1. 수집 및 활용 목적")
            bulletList([
                "맞춤형 서비스 안내: 서비스 기능 추천, 보증 관리 팁 및 신규 서비스 업데이트 소식 안내",
                "이벤트 및 프로모션: 각종 경품 행사, 제휴 이벤트 참여 안내 및 혜택 제공",
                "광고성 정보 전송: 앱 푸시 알림을 통한 광고성 정보 제공",
            ])

            sectionHeader("2. 수집 항목")
            bulletList([
                "이메일 주소, 휴대전화번호, 마케팅 수신 동의 여부, 수신 동의 일시 및 채널 정보",
            ])

            sectionHeader("3. 보유 및 이용 기간")
            bulletList([
                "회원 탈퇴 시까지 또는 이용자가 마케팅 정보 수신 동의를 철회하는 시점까지 보유하며, 철회 즉시 마케팅 활용 목적의 데이터는 파기됩니다.",
                "수신 동의의 철회 이력은 관련 법령에 따라 부정 수신 방지 및 동의 여부 증빙을 위해 최대 1년간 보관될 수 있습니다.",
            ])

            sectionHeader("4. 수신 동의 철회 및 설정 안내")
            bulletList([
                "이용자는 언제든지 [마이페이지] → [설정 알림]에서 광고성 푸시 알림 수신을 거부하거나 동의를 철회할 수 있으며, 철회 시 별도의 비용은 발생하지 않습니다.",
                "서비스 제공에 필수적인 안내(예: 보증 만료 알림 등)는 마케팅 수신 동의 여부와 관계없이 발송될 수 있습니다.",
            ])

            sectionHeader("5. 동의 거부의 권리")
            bulletList([
                "이용자는 본 마케팅 정보 수신 동의를 거부할 권리가 있으며, 동의를 거부하더라도 보트랩 서비스의 기본 기능은 정상적으로 이용할 수 있습니다.",
            ])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 타이포그래피 헬퍼 (TermsOfServiceView/PrivacyPolicyView와 동일 스타일)

    private func pageTitle(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.bold, size: 20))
            .foregroundStyle(Color.gray900)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.bold, size: 15))
            .foregroundStyle(Color.gray900)
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.regular, size: 14))
            .foregroundStyle(Color.gray700)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: .spacing4) {
                    Text("•")
                    Text(item)
                }
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray700)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    MarketingConsentView(onBack: {})
}
