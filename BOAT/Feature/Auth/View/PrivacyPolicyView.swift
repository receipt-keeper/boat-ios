//
//  PrivacyPolicyView.swift
//  BOAT
//
//  개인정보 처리방침 전문 화면. 마이페이지, 그리고 회원가입(TermsView)의
//  "개인정보처리방침 보기" 탭에서 진입한다. TermsOfServiceView와 동일한 타이포그래피로 구성.
//

import SwiftUI

struct PrivacyPolicyView: View {

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
            Text("privacy_policy.title")
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
            pageTitle("개인정보 처리방침 (보트랩)")

            paragraph("'보트랩 서비스'(이하 '운영자')는 개인정보 보호법 제30조에 따라 이용자의 개인정보를 보호하고 관련 고충을 신속하고 원활하게 처리하기 위하여 다음과 같이 개인정보 처리방침을 수립·공개합니다.")

            article("제1조 (개인정보의 수집 항목 및 방법)")
            subLabel("수집 항목")
            bulletList([
                "계정 정보: 구글/애플 로그인 시 제공되는 이메일 주소, 식별자(UID), 프로필 정보(이름, 사진)",
                "서비스 이용 정보: 회원이 직접 업로드한 영수증 및 보증서 이미지, 이미지 분석으로 추출된 데이터(구매처, 구매일시, 금액, 품목, 보증기간 등)",
                "자동 수집 정보: 서비스 이용 기록, 기기 정보(단말기 모델, OS 정보), IP 주소, 접속 로그, 쿠키(Cookie)",
            ])
            subLabel("수집 방법")
            bulletList([
                "이용자가 서비스에 직접 입력하거나, 앱 이용 과정에서 자동으로 생성되는 정보를 수집합니다.",
            ])

            article("제2조 (개인정보의 수집 및 이용 목적)")
            paragraph("운영자는 다음의 목적을 위해 개인정보를 처리합니다.")
            bulletList([
                "회원 식별 및 계정 관리, 부정이용 방지",
                "영수증·보증서 데이터 추출 및 보증기간 알림 서비스 제공",
                "서비스 품질 향상, 오류 시정, 신규 기능 개발 및 서비스 개선",
                "이용문의에 대한 회신 및 민원 처리",
            ])

            article("제3조 (개인정보의 보유 및 이용 기간)")
            paragraph("""
            운영자는 원칙적으로 이용자의 회원 탈퇴 시까지 개인정보를 보유 및 이용합니다.
            단, 관련 법령(전자상거래법 등)에 따라 보관이 필요한 경우에는 다음 기간 동안 보관합니다.
            """)
            bulletList([
                "계약 또는 청약철회 등에 관한 기록: 5년",
                "대금결제 및 재화 등의 공급에 관한 기록: 5년",
                "소비자의 불만 또는 분쟁처리에 관한 기록: 3년",
                "웹사이트 로그 기록 자료: 3개월",
                "부정이용 방지를 위하여 부정 가입 및 이용 기록은 탈퇴일로부터 1년간 보관합니다.",
            ])

            article("제4조 (개인정보의 파기절차 및 방법)")
            paragraph("운영자는 보유 기간이 경과하거나 목적이 달성된 경우 지체 없이 파기합니다.")
            bulletList([
                "파기 방법: 전자적 파일 형태는 복구가 불가능한 기술적 방법을 사용하여 삭제하며, 종이 등 기록물은 분쇄하거나 소각하여 파기합니다.",
            ])

            article("제5조 (개인정보 처리 위탁)")
            paragraph("운영자는 원활한 서비스 제공을 위해 아래와 같이 업무를 위탁하고 있습니다.")
            bulletList([
                "수탁자: Google Cloud",
                "위탁 업무: AI 기반 데이터 분석 및 클라우드 서버 운영",
            ])

            article("제6조 (이용자의 권리와 의무 및 행사방법)")
            bulletList([
                "이용자는 언제든지 자신의 개인정보 열람, 정정, 삭제, 처리 정지를 요구할 수 있습니다.",
                "이용자의 요청에 따라 삭제된 개인정보 및 서비스 데이터는 복구가 어려울 수 있으므로, 삭제 요청 전 필요한 데이터를 별도로 보관하는 것을 권장 드립니다.",
                "이용자는 자신의 정보를 최신 상태로 유지해야 하며, 부정확한 정보 입력으로 인한 문제는 본인에게 책임이 있습니다. 타인의 정보를 도용하여 가입하는 경우 자격이 상실될 수 있습니다.",
            ])

            article("제7조 (개인정보의 안전성 확보 조치)")
            paragraph("운영자는 개인정보 분실, 도난, 유출, 변조, 훼손 방지를 위해 다음과 같은 기술적·관리적 대책을 강구합니다.")
            bulletList([
                "해킹 및 컴퓨터 바이러스 대비 최신 백신 프로그램 및 침입차단 시스템 운영",
                "개인정보 처리 담당자 최소화 및 정기적인 보안 교육 실시",
            ])

            article("제8조 (쿠키의 설치·운영 및 거부)")
            paragraph("운영자는 맞춤 서비스를 제공하기 위해 쿠키를 사용합니다.")
            bulletList([
                "이용자는 웹브라우저 설정을 통해 쿠키 허용, 차단 여부를 결정할 수 있습니다. 다만, 쿠키 저장을 거부할 경우 로그인이 필요한 일부 서비스 이용에 어려움이 있을 수 있습니다.",
            ])

            article("제9조 (개인정보 보호 책임자 및 문의처)")
            paragraph("개인정보 처리에 관한 문의, 불만 처리, 피해 구제 등은 아래로 문의하시기 바랍니다.")
            bulletList([
                "개인정보 보호 책임자: 유빈 (PM)",
                "이메일: team.swyp8.app@gmail.com",
            ])

            article("제10조 (권익침해 구제방법)")
            paragraph("정보주체는 아래 기관을 통해 개인정보 침해에 대한 상담이나 분쟁 조정을 신청할 수 있습니다.")
            bulletList([
                "개인정보분쟁조정위원회: 1833-6972 (www.kopico.go.kr)",
                "개인정보침해신고센터: 118 (privacy.kisa.or.kr)",
            ])

            article("제11조 (방침 변경 및 고지의 의무)")
            paragraph("본 개인정보 처리방침은 2026년 7월 12일부터 적용됩니다. 운영자는 방침을 개정하는 경우, 적용일자 및 변경내용을 명시하여 현행 방침과 함께 서비스 내 게시하며, 이용자의 권리 또는 의무에 중대한 영향을 미치는 변경의 경우 서비스 내 게시와 더불어 이메일, 푸시 알림 등 이용자가 충분히 인지할 수 있는 방법으로 별도 고지합니다.")

            article("[부칙]")
            paragraph("본 방침은 2026. 07. 12.부터 시행됩니다.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 타이포그래피 헬퍼 (TermsOfServiceView와 동일 스타일)

    private func pageTitle(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.bold, size: 20))
            .foregroundStyle(Color.gray900)
    }

    private func article(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.bold, size: 15))
            .foregroundStyle(Color.gray900)
    }

    private func subLabel(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.semibold, size: 14))
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
    PrivacyPolicyView(onBack: {})
}
