//
//  FreeAnalysisBanner.swift
//  BOAT
//
//  홈 상단 "영수증 무료 분석" 배너 — 스파클 아이콘 + 텍스트 + 잔여 횟수 pill.
//

import SwiftUI

struct FreeAnalysisBanner: View {

    /// 남은 무료 분석 토큰 수 (User.freeAnalysisTokensRemaining)
    let remaining: Int

    var body: some View {
        HStack(spacing: .spacing8) {
            Image("icSparkle")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)

            Text("home.free_analysis")
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(Color.gray900)

            Spacer(minLength: 0)

            Text("home.free_analysis_remaining \(remaining)")
                .font(.pretendard(.semibold, size: 13))
                .foregroundStyle(Color.colorWhite)
                .padding(.horizontal, .spacing12)
                .padding(.vertical, 6)
                .background(Color.brandPrimary, in: Capsule())
        }
        .padding(.horizontal, .spacing16)
        .frame(height: 52)
        .background(Color.brandSenary, in: RoundedRectangle(cornerRadius: .roundedXl))
        .overlay(
            RoundedRectangle(cornerRadius: .roundedXl)
                .stroke(Color.brandTertiary, lineWidth: 1)
        )
    }
}

#Preview {
    FreeAnalysisBanner(remaining: 3)
        .padding()
        .background(Color.gray50)
}
