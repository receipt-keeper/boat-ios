//
//  HomeSkeleton.swift
//  BOAT
//
//  홈 탭 로딩 스켈레톤 — 초기 API(만료 예정/최근 등록 등) 조회 중 표시할 데이터가 없을 때
//  실제 레이아웃 자리를 셔머 플레이스톨더로 채운다.
//  - hasList=true : 일반(대시보드) 레이아웃 스켈레톤(만료 예정 히어로 + 배너 + 최근 목록)
//  - hasList=false: 초기(온보딩) 레이아웃 스켈레톤(등록 유도 카드 + 배너)
//

import SwiftUI

struct HomeSkeleton: View {
    /// 직전에 등록된 영수증이 있었는지 — 일반/초기 레이아웃 스켈레톤 선택.
    let hasList: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if hasList {
                generalBody
            } else {
                initialBody
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, .spacing20)
        // 로딩 중에는 상단 블루 그라데이션까지 흰색으로 덮는다(상태바 영역 포함).
        .background { Color.colorWhite.ignoresSafeArea() }
    }

    // MARK: - 헤더 (타이틀 + 검색/알림)

    private var header: some View {
        HStack {
            ShimmerBox(cornerRadius: .roundedFull)
                .frame(width: 150, height: 26)
            Spacer()
            Circle().fill(shimmerFill).frame(width: 20, height: 20)
            Circle().fill(shimmerFill).frame(width: 20, height: 20)
        }
        .frame(height: 56)
    }

    // MARK: - 일반(대시보드) 스켈레톤

    private var generalBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            // AS 만료 예정 히어로 카드
            ShimmerBox(cornerRadius: .rounded2xl)
                .frame(height: 300)

            Spacer().frame(height: .spacing20)
            // 가전제품 필수 아이템 배너
            ShimmerBox(cornerRadius: .roundedXl)
                .frame(height: 110)

            Spacer().frame(height: .spacing24)
            // 최근 등록된 영수증 타이틀
            ShimmerBox(cornerRadius: .roundedFull)
                .frame(width: 140, height: 18)

            Spacer().frame(height: .spacing12)
            VStack(spacing: .spacing12) {
                ForEach(0..<5, id: \.self) { _ in recentRow }
            }
        }
    }

    private var recentRow: some View {
        HStack(spacing: .spacing16) {
            ShimmerBox(cornerRadius: .roundedXl)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 6) {
                ShimmerBox(cornerRadius: .roundedFull).frame(width: 160, height: 13)
                ShimmerBox(cornerRadius: .roundedFull).frame(width: 120, height: 13)
            }
            Spacer()
        }
        .padding(.horizontal, .spacing16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: .roundedXl)
                .stroke(Color.gray100, lineWidth: 1)
        )
    }

    // MARK: - 초기(온보딩) 스켈레톤

    private var initialBody: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            // 영수증 등록 유도 CTA 카드 (정사각형에 가까운 배너)
            ShimmerBox(cornerRadius: .rounded3xl)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)

            // 가전제품 필수 아이템 배너
            ShimmerBox(cornerRadius: .roundedXl)
                .frame(height: 110)
        }
        .padding(.top, .spacing16)
    }
}

/// 스켈레톤 원형/보조용 단색 필 — ShimmerBox와 동일 톤.
private let shimmerFill = Color(hex: "#E9EEF6")

#Preview("일반") { HomeSkeleton(hasList: true) }
#Preview("초기") { HomeSkeleton(hasList: false) }
