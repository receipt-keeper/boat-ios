//
//  TermsOfServiceView.swift
//  BOAT
//
//  서비스 이용약관 전문 화면. 마이페이지 → 서비스 이용약관, 그리고 회원가입(TermsView)의
//  "보기" 탭에서 진입한다. 정적 텍스트 표시 전용 화면.
//

import SwiftUI

struct TermsOfServiceView: View {

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
            Text("terms_of_service.title")
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
            pageTitle("서비스 이용약관")

            chapter("제 1장 총칙")

            article("제1조 (목적)")
            paragraph("본 약관은 '보트랩' 서비스(이하 \u{201C}서비스\u{201D})가 제공하는 영수증 및 보증 관리 서비스의 이용과 관련하여 운영자와 이용자 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.")

            article("제2조 (용어의 정의)")
            paragraph("""
            \u{201C}운영자\u{201D}: 보트랩 서비스를 운영하는 주체를 의미합니다.
            \u{201C}보트랩\u{201D}: 운영자가 제공하는 웹사이트 및 모바일 애플리케이션을 의미합니다.
            \u{201C}회원\u{201D}: 본 약관에 동의하고 Apple, Google 등 소셜 로그인 계정을 통해 서비스에 가입하여 서비스를 이용하는 자를 의미합니다.
            \u{201C}서비스\u{201D}: 운영자가 제공하는 영수증 디지털화, 보증 기간 관리 및 관련 제반 서비스를 의미합니다.
            \u{201C}데이터\u{201D}: 회원이 서비스를 통해 업로드한 영수증 및 보증서 이미지, 그리고 이를 AI 기술로 분석하여 추출된 텍스트, 보증 기간, 보증 내용 등 일체의 정보를 의미합니다.
            \u{201C}유료서비스\u{201D}: 운영자가 유료로 제공하는 제반 서비스를 의미합니다.
            \u{201C}크레딧\u{201D}: 서비스 내 기능(영수증 및 보증서 분석 등)을 이용하기 위한 횟수 차감 방식의 전용 재화를 의미합니다.
            """)

            article("제3조 (약관의 게시 및 변경)")
            paragraph("""
            본 약관은 서비스 내 화면 또는 운영자가 제공하는 방법을 통해 게시되며, 이용자가 약관에 동의함으로써 효력이 발생합니다.
            운영자는 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있습니다.
            운영자는 약관을 변경하는 경우, 적용일자 및 변경내용을 명시하여 현행 약관과 함께 서비스 내 게시하며, 이용자의 권리 또는 의무에 중대한 영향을 미치는 변경의 경우 서비스 내 게시와 더불어 이메일, 푸시 알림 등 이용자가 충분히 인지할 수 있는 방법으로 별도 고지합니다.
            """)

            chapter("제 2장 서비스 이용계약")

            article("제4조 (회원가입 및 이용계약의 체결)")
            paragraph("""
            서비스 이용은 Apple, Google 등 소셜 로그인 방식을 통해 회원가입을 완료한 후 이용 가능합니다.
            이용자는 Google, Apple 등 운영자가 제공하는 인증 수단을 통해 회원가입할 수 있으며, 본 약관 및 개인정보처리방침에 동의함으로써 이용계약이 성립합니다.
            운영자는 타인의 명의 도용, 허위 정보 기재, 만 14세 미만 가입, 이전에 약관 위반으로 자격을 상실한 경우 등 정당한 사유가 있을 시 가입을 제한할 수 있습니다.
            """)

            article("제5조 (이용계약의 해지 및 이용제한)")
            paragraph("""
            회원은 언제든 서비스 내 메뉴를 통해 탈퇴할 수 있습니다.
            운영자는 다음 각 호에 해당하는 부정한 행위가 확인될 경우 이용자의 서비스 이용을 제한하거나 계정을 정지할 수 있습니다.
            """)
            numberedList([
                "부정한 방법으로 크레딧을 적립하거나 사용하는 경우",
                "본인의 영수증이 아닌 타인의 영수증을 무단으로 업로드하거나, 타인의 개인정보가 포함된 데이터를 임의로 등록하는 행위",
                "서비스 운영을 고의로 방해하거나 시스템 해킹 등을 시도하는 경우",
                "기타 본 약관 및 관련 법령을 위반하는 행위",
            ])

            chapter("제 3장 서비스 제공 및 관리")

            article("제6조 (서비스의 내용)")
            paragraph("보트랩은 이미지 스캔을 통한 영수증 디지털화, 보증기간 알림, 자산 기록 서비스를 제공합니다. 서비스는 연중무휴 24시간 제공을 원칙으로 하되, 시스템 보수나 정전 등 불가항력적 사유 시 중단될 수 있습니다.")

            article("제7조 (데이터 및 크레딧 관리)")
            paragraph("""
            데이터 기준: 서비스 운영 및 데이터 무결성 유지를 위해, 서버에 저장된 데이터를 최종 기준으로 합니다. 클라이언트(사용자 기기)와 서버 간 데이터 불일치가 발생할 경우 서버의 수치를 우선 적용합니다.
            크레딧 관리: 크레딧은 양도, 상속, 담보 제공이 불가능하며, 부정 적립된 크레딧은 발견 즉시 회수합니다.
            """)

            chapter("제 4장 유료서비스 및 환불")

            article("제8조 (유료서비스 결제 및 환불)")
            numberedList([
                "유료서비스 이용 시 이용대금을 납부해야 하며, 결제 정보 입력의 책임은 이용자 본인에게 있습니다.",
                "유료서비스는 이용자의 선택에 따라 건별 결제(1회성) 또는 구독형 결제(정기) 방식 중 선택하여 이용할 수 있습니다.",
                "환불 규정:\n- 이용자 귀책 시: 1회성 결제 서비스는 사용 여부에 따라 차감 후 환불하며, 구독형 서비스는 결제된 이용 기간 내 해지 시 관련 법령에 따라 잔여 기간을 일할 계산하여 환불합니다.\n- 운영자 귀책 시: 서비스 장애나 미제공 시 전액 환불합니다.",
                "환불은 결제수단과 동일한 방법으로 진행하며, 환불 의무가 발생한 날로부터 3영업일 이내에 처리합니다.",
            ])

            chapter("제 5장 개인정보 및 책임 제한")

            article("제9조 (개인정보 보호)")
            paragraph("서비스 이용과 관련된 개인정보의 수집, 이용, 보호 등에 관한 사항은 별도로 고지하는 '개인정보처리방침'에 따릅니다.")

            article("제10조 (보증 정보의 신뢰도)")
            paragraph("본 서비스는 AI OCR 분석 결과를 기반으로 영수증 및 보증 정보를 제공하며, 정확하고 유용한 정보를 제공하기 위해 최선의 노력을 다합니다. 다만, 분석 과정에서 실제 정보와 차이가 발생할 수 있으므로, 중요한 보증 관련 확인 시 원본 증빙 서류를 대조할 것을 권장합니다. 운영자의 고의 또는 중대한 과실이 없는 한, 시스템상 발생하는 분석 정보의 차이로 인한 손해에 대하여 운영자는 책임을 부담하지 않습니다.")

            article("제11조 (손해배상 및 면책)")
            paragraph("""
            운영자는 천재지변, 이동통신사 장애 등 운영자의 귀책사유가 없는 불가항력적 장애에 대해 책임을 지지 않습니다.
            이용자의 부정한 행위(타인 데이터 무단 업로드 등)로 인해 발생하는 모든 민·형사상 책임은 해당 회원 본인에게 있으며, 운영자는 이에 대해 어떠한 책임도 지지 않습니다.
            이용자 간 발생한 분쟁에 대해 운영자는 개입할 의무가 없습니다.
            """)

            article("제12조 (분쟁 조정 및 관할)")
            paragraph("본 약관 관련 분쟁은 대한민국 법령을 준거법으로 하며, 민사소송법상 관할법원을 관할로 합니다.")

            article("[부칙]")
            paragraph("본 약관은 2026. 07. 12.부터 시행됩니다.")

            article("[고객 문의]")
            paragraph("서비스 이용 중 불편사항이나 문의사항은 team.swyp8.app@gmail.com으로 연락해주시기 바랍니다.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 타이포그래피 헬퍼

    private func pageTitle(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.bold, size: 20))
            .foregroundStyle(Color.gray900)
    }

    private func chapter(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.bold, size: 17))
            .foregroundStyle(Color.gray900)
    }

    private func article(_ text: String) -> some View {
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

    private func numberedList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: .spacing4) {
                    Text("\(index + 1).")
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
    TermsOfServiceView(onBack: {})
}
