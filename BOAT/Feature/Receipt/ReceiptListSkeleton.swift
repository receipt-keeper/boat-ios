//
//  ReceiptListSkeleton.swift
//  BOAT
//
//  목록 탭 로딩 스켈레톤 — API 조회 중 표시할 데이터가 없을 때 헤더/탭/필터칩/카운트/카드
//  자리를 셔머 플레이스홀더로 채운다. (하단 플로팅 탭바는 MainTabView가 그대로 유지)
//

import SwiftUI

struct ReceiptListSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더 (타이틀 + 검색/알림 아이콘)
            HStack {
                ShimmerBox(cornerRadius: .roundedFull)
                    .frame(width: 128, height: 26)
                Spacer()
                Circle().fill(shimmerFill).frame(width: 22, height: 22)
                Circle().fill(shimmerFill).frame(width: 22, height: 22)
            }
            .frame(height: 56)
            .padding(.horizontal, .spacing20)

            // inner tab (전체/만료예정/만료) + 밑줄
            HStack(spacing: .spacing24) {
                ShimmerBox(cornerRadius: .roundedFull).frame(width: 56, height: 16)
                ShimmerBox(cornerRadius: .roundedFull).frame(width: 72, height: 16)
                ShimmerBox(cornerRadius: .roundedFull).frame(width: 56, height: 16)
                Spacer()
            }
            .frame(height: 44)
            .padding(.horizontal, .spacing20)
            Rectangle().fill(Color.gray200).frame(height: 1)

            Spacer().frame(height: .spacing12)
            // 카테고리 필터 칩
            HStack(spacing: .spacing8) {
                ForEach([56, 72, 88, 72, 40], id: \.self) { w in
                    ShimmerBox(cornerRadius: .roundedFull)
                        .frame(width: CGFloat(w), height: 40)
                }
            }
            .padding(.horizontal, .spacing20)

            Spacer().frame(height: .spacing16)
            // 카운트 + 정렬
            HStack {
                ShimmerBox(cornerRadius: .roundedFull).frame(width: 64, height: 16)
                Spacer()
                ShimmerBox(cornerRadius: .roundedFull).frame(width: 96, height: 16)
            }
            .padding(.horizontal, .spacing20)

            Spacer().frame(height: .spacing16)
            // 카드 목록
            VStack(spacing: .spacing12) {
                ForEach(0..<6, id: \.self) { _ in cardSkeleton }
            }
            .padding(.horizontal, .spacing20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray50)
    }

    private var cardSkeleton: some View {
        HStack(spacing: .spacing16) {
            ShimmerBox(cornerRadius: .roundedLg)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: .spacing8) {
                ShimmerBox(cornerRadius: .roundedFull).frame(width: 200, height: 14)
                ShimmerBox(cornerRadius: .roundedFull).frame(width: 150, height: 14)
            }
            Spacer()
            ShimmerBox(cornerRadius: .roundedSm).frame(width: 56, height: 26)
        }
        .padding(.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
        .overlay(
            RoundedRectangle(cornerRadius: .rounded2xl)
                .stroke(Color.gray100, lineWidth: 1)
        )
    }
}

/// 스켈레톤 원형/보조용 단색 필 — ShimmerBox와 동일 톤.
private let shimmerFill = Color(hex: "#E9EEF6")

#Preview {
    ReceiptListSkeleton()
}
