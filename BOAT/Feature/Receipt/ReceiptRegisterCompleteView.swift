//
//  ReceiptRegisterCompleteView.swift
//  BOAT
//
//  영수증 등록 성공 직후 보여주는 완료 화면.
//  "홈으로 가기" → 등록 플로우 전체 닫고 홈 복귀 / "보러가기" → 방금 등록한 영수증 상세로 이동.
//

import SwiftUI

struct ReceiptRegisterCompleteView: View {

    let receiptId: String
    /// 등록 플로우 전체를 닫고 홈으로 복귀 (상위에서 처리)
    let onGoHome: () -> Void

    @State private var showDetail = false
    @State private var toast = BoatToastState()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("icon_complete")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Spacer().frame(height: .spacing20)

            Text("receipt.complete.title")
                .font(.pretendard(.bold, size: 22))
                .foregroundStyle(Color.gray900)
                .multilineTextAlignment(.center)

            Spacer().frame(height: .spacing8)

            Text("receipt.complete.subtitle")
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.gray500)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()

            HStack(spacing: .spacing12) {
                homeButton
                viewButton
            }
            .padding(.horizontal, .spacing20)
            .padding(.bottom, .spacing16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colorWhite)
        // 뒤로가기 없이 상세로 이동 — 여기서 뒤로가면(onBack) 완료 화면으로 돌아오지 않고 바로 홈으로.
        .fullScreenCover(isPresented: $showDetail) {
            ReceiptDetailView(
                receiptId: receiptId,
                onBack: { showDetail = false },
                onDeleted: {
                    toast.show(String(localized: "detail.deleted_toast"), type: .info)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        onGoHome()
                    }
                },
                showCloseButton: true
            )
        }
        .boatToastHost(toast)
    }

    private var homeButton: some View {
        Button(action: onGoHome) {
            Text("receipt.complete.go_home")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
                .overlay(
                    RoundedRectangle(cornerRadius: .roundedXl)
                        .stroke(Color.brandTertiary, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var viewButton: some View {
        Button {
            showDetail = true
        } label: {
            Text("receipt.complete.view")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(Color.colorWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.brandPrimary, in: RoundedRectangle(cornerRadius: .roundedXl))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReceiptRegisterCompleteView(receiptId: "preview-id", onGoHome: {})
}
