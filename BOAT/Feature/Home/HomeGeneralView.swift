//
//  HomeGeneralView.swift
//  BOAT
//
//  홈 일반 콘텐츠 — AS 만료 예정(파란 히어로 카드 + 보보 캐릭터 + 가로 카드 캐러셀) +
//  가전제품 필수 아이템 배너 + 최근 등록 영수증(세로형) + 더보기.
//  Android HomeGeneralContent 대응.
//

import SwiftUI

struct HomeGeneralView: View {

    let expiring: [ExpiringWarranty]
    /// 헤더의 "N건" — 실제 만료 예정 전체 건수(표시되는 카드 수와 다를 수 있음)
    var expiringTotalCount: Int? = nil
    let recent: [RecentReceipt]
    var onExpiringMore: () -> Void = {}
    var onRecentMore: () -> Void = {}
    /// 카드 탭 → 영수증 상세로 이동
    var onExpiringTap: (ExpiringWarranty) -> Void = { _ in }
    var onRecentTap: (RecentReceipt) -> Void = { _ in }

    private var displayedExpiringCount: Int { expiringTotalCount ?? expiring.count }

    var body: some View {
        // 스크롤은 상위(HomeView)에서 전체 화면을 대상으로 처리하므로 여기선 일반 VStack.
        VStack(alignment: .leading, spacing: 0) {
            // ── AS 만료 예정 ──
            Spacer().frame(height: .spacing8)
            if expiring.isEmpty {
                ExpiringEmptyBanner(onMore: onExpiringMore)
                    .padding(.horizontal, .spacing20)
            } else {
                ExpiringWarrantySection(
                    expiring: expiring,
                    totalCount: displayedExpiringCount,
                    onMore: onExpiringMore,
                    onTap: onExpiringTap
                )
                .padding(.horizontal, .spacing20)
            }

            // ── 가전제품 필수 아이템 배너 ──
            Spacer().frame(height: .spacing20)
            AccessoryBanner()
                .padding(.horizontal, .spacing20)

            // ── 최근 등록된 영수증 ──
            Spacer().frame(height: .spacing24)
            Text("home.recent_title")
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)
                .padding(.horizontal, .spacing20)

            Spacer().frame(height: .spacing12)
            VStack(spacing: .spacing12) {
                ForEach(recent) { item in
                    RecentReceiptItem(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture { onRecentTap(item) }
                }
                Spacer().frame(height: .spacing4)
                moreButton
            }
            .padding(.horizontal, .spacing20)

            Spacer().frame(height: 92) // 플로팅 하단 바 높이만큼 여백
        }
    }

    private var moreButton: some View {
        Button(action: onRecentMore) {
            HStack(spacing: 2) {
                Text("home.more")
                    .font(.pretendard(.medium, size: 15))
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.badgeSafeBg, in: RoundedRectangle(cornerRadius: .roundedXl))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 히어로 카드 공통 그라데이션 (Android 0xFF3E82F7 → 0xFF6FA1F8)

private let heroGradient = LinearGradient(
    colors: [Color(hex: "#3E82F7"), Color(hex: "#6FA1F8")],
    startPoint: .top,
    endPoint: .bottom
)

// MARK: - AS 만료 예정 섹션 (파란 히어로 카드 + 캐릭터 레이어 + 가로 카드 캐러셀)

/// 몸통(img_happy_bobo) → 카드 캐러셀 → 손+태그(img_happy_bobo_hand) 순으로 z-order를 쌓아
/// 손이 카드 위에 얹힌 것처럼 보이게 한다. 몸통/손은 같은 캔버스라 동일 크기·위치로 겹쳐야 이어진다.
private struct ExpiringWarrantySection: View {
    let expiring: [ExpiringWarranty]
    let totalCount: Int
    var onMore: () -> Void = {}
    var onTap: (ExpiringWarranty) -> Void = { _ in }

    @State private var visibleID: String?

    // 다음 카드가 우측에 살짝 걸쳐 보이도록(peek) 산정 — Android(screenWidth - 88)와 동일.
    private var cardWidth: CGFloat { UIScreen.main.bounds.width - 88 }
    // 몸통/손 레이어 공통 크기·오프셋 (반드시 두 레이어가 동일 값 공유)
    private let mascotSize = CGSize(width: 90, height: 127)
    private let mascotOffsetY: CGFloat = 8
    private let mascotTrailing: CGFloat = 44

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 1) 몸통 — 맨 아래 (카드에 하단부가 가려진다)
            mascot("img_happy_bobo")

            // 2) 헤더 + 카드 캐러셀 + 인디케이터
            VStack(spacing: 0) {
                header

                Spacer().frame(height: 30) // 헤더-카드 간격 (손 태그가 카드 텍스트를 덜 가리도록)

                carousel

                Spacer().frame(height: 14)
                CarouselIndicator(count: expiring.count, activeIndex: activeIndex)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, .spacing24)
            .padding(.bottom, .spacing20)
            .frame(maxWidth: .infinity)

            // 3) 손 + 보증 태그 — 맨 위 (몸통과 완전히 동일한 크기·위치)
            mascot("img_happy_bobo_hand")
        }
        .background(heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: .rounded2xl))
    }

    private var activeIndex: Int {
        guard let visibleID, let idx = expiring.firstIndex(where: { $0.id == visibleID }) else { return 0 }
        return idx
    }

    private func mascot(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: mascotSize.width, height: mascotSize.height)
            .offset(y: mascotOffsetY)
            .padding(.trailing, mascotTrailing)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("home.expiring_caption")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundStyle(Color.colorWhite.opacity(0.85))
                HStack(spacing: 6) {
                    Text("home.expiring_title")
                        .font(.pretendard(.bold, size: 20))
                        .foregroundStyle(Color.colorWhite)
                    Text("home.expiring_count \(totalCount)")
                        .font(.pretendard(.bold, size: 20))
                        .foregroundStyle(Color.colorWhite)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 96) // 캐릭터 영역 침범 방지

            Button(action: onMore) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.colorWhite)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .spacing20)
    }

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: .spacing12) {
                ForEach(expiring) { item in
                    ExpiringWarrantyCard(item: item)
                        .frame(width: cardWidth)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(item) }
                        .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, .spacing20, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $visibleID, anchor: .leading)
    }
}

// MARK: - AS 만료 예정 가로형 카드 (흰 카드: D-day 뱃지 + 보증종료일 / 구분선 / 썸네일+정보)

private struct ExpiringWarrantyCard: View {
    let item: ExpiringWarranty

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                DDayBadge(dDay: item.dDay)
                Spacer(minLength: .spacing8)
                Text("home.warranty_end \(item.expiryLabel)")
                    .font(.pretendard(.bold, size: 14))
                    .foregroundStyle(Color.brandPrimary)
                    .lineLimit(1)
            }

            Spacer().frame(height: 14)
            Rectangle().fill(Color.gray100).frame(height: 1)
            Spacer().frame(height: 14)

            HStack(spacing: 14) {
                thumbnail
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.productName)
                        .font(.pretendard(.bold, size: 17))
                        .foregroundStyle(Color.gray900)
                        .lineLimit(1)
                    Spacer().frame(height: 8)
                    labelValue("home.label.brand", item.brand)
                    Spacer().frame(height: 6)
                    labelValue("home.label.purchase", item.purchaseDate)
                }
            }
        }
        .padding(.spacing16)
        .frame(minHeight: 197)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: .roundedXl)
            .fill(Color.brandSenary)
            .frame(width: 56, height: 56)
            .overlay {
                if let name = item.localImageName {
                    Image(name).resizable().scaledToFit()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.gray400)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: .roundedXl))
    }

    private func labelValue(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray700)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray700)
                .lineLimit(1)
        }
    }
}

// MARK: - 캐러셀 페이지 인디케이터 (현재 카드는 넓은 pill, 나머지는 작은 dot)

private struct CarouselIndicator: View {
    let count: Int
    let activeIndex: Int

    var body: some View {
        if count > 0 {
            HStack(spacing: 6) {
                ForEach(0..<count, id: \.self) { index in
                    let active = index == activeIndex
                    Capsule()
                        .fill(active ? Color.colorWhite : Color.colorWhite.opacity(0.4))
                        .frame(width: active ? 16 : 6, height: 6)
                }
            }
        }
    }
}

// MARK: - AS 만료 예정 0건 배너 (우는 보보 + 안내 박스)

/// 몸통(img_crying_bobo) → 안내 박스 → 손+태그(img_crying_bobo_hand) 순으로 z-order를 쌓아
/// 손이 안내 박스 위에 얹힌 것처럼 보이게 한다.
private struct ExpiringEmptyBanner: View {
    var onMore: () -> Void = {}

    private let mascotSize = CGSize(width: 88, height: 107)
    private let mascotTrailing: CGFloat = 32

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 1) 몸통 — 맨 아래 (안내 박스에 하단이 가려진다)
            mascot("img_crying_bobo")

            VStack(spacing: 0) {
                // 상단 헤더 (수직 중앙 정렬, 높이 84)
                ZStack {
                    HStack(alignment: .center, spacing: 0) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("home.expiring_caption")
                                .font(.pretendard(.regular, size: 13))
                                .foregroundStyle(Color.colorWhite.opacity(0.85))
                            HStack(spacing: 6) {
                                Text("home.expiring_title")
                                    .font(.pretendard(.bold, size: 20))
                                    .foregroundStyle(Color.colorWhite)
                                Text("home.expiring_count \(0)")
                                    .font(.pretendard(.bold, size: 20))
                                    .foregroundStyle(Color.colorWhite)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 100) // 캐릭터 영역 침범 방지

                        Button(action: onMore) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.colorWhite)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 84)

                // 2) 안내 박스 — 몸통 위, 손 아래
                Text("home.expiring_empty")
                    .font(.pretendard(.medium, size: 14))
                    .foregroundStyle(Color.colorWhite)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .frame(height: 112)
                    .padding(.horizontal, 14)
                    .background(Color.colorWhite.opacity(0.18), in: RoundedRectangle(cornerRadius: .roundedXl))
            }
            .padding(.spacing20)

            // 3) 손 + 보증 만료 태그 — 맨 위
            mascot("img_crying_bobo_hand")
        }
        .background(heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: .rounded2xl))
    }

    private func mascot(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: mascotSize.width, height: mascotSize.height)
            .padding(.trailing, mascotTrailing)
    }
}

// MARK: - 가전제품 필수 아이템 배너 (Android AccessoryBanner 대응)

struct AccessoryBanner: View {
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: .spacing4) {
                    Text("home.card.popular.title")
                        .font(.pretendard(.bold, size: 18))
                        .foregroundStyle(Color.gray900)
                    Text("home.card.popular.desc")
                        .font(.pretendard(.regular, size: 13))
                        .foregroundStyle(Color.gray500)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: .spacing12)
                Image("img_banner_accessories")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
            .padding(.horizontal, .spacing24)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(Color(hex: "#E9F4FF"), in: RoundedRectangle(cornerRadius: .roundedXl))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 최근 등록 영수증 세로형 아이템 (옅은 쿨블루 카드 + 흰 썸네일 박스)

private struct RecentReceiptItem: View {
    let item: RecentReceipt

    var body: some View {
        HStack(spacing: .spacing16) {
            // 흰 라운드 박스 안에 축소된 카테고리 이미지
            RoundedRectangle(cornerRadius: .roundedXl)
                .fill(Color.colorWhite)
                .frame(width: 56, height: 56)
                .overlay {
                    if let name = item.localImageName {
                        Image(name).resizable().scaledToFit().padding(10)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.brandPrimary.opacity(0.4))
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: .spacing8) {
                    Text(item.productName)
                        .font(.pretendard(.bold, size: 17))
                        .foregroundStyle(Color.gray900)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    (item.daysAgo <= 0
                         ? Text("home.days_ago_today")
                         : Text("home.days_ago \(item.daysAgo)"))
                        .font(.pretendard(.semibold, size: 15))
                        .foregroundStyle(Color(hex: "#5C9DFF"))
                }
                HStack(spacing: 0) {
                    Text("home.label.purchase")
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color.gray500)
                    Text("  |  ")
                        .font(.pretendard(.regular, size: 12))
                        .foregroundStyle(Color.gray400)
                    Text(item.purchaseDate)
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color.gray500)
                }
            }
        }
        .padding(.horizontal, .spacing16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#F2F6FC"), in: RoundedRectangle(cornerRadius: .roundedXl))
    }
}

#Preview("만료 예정 있음") {
    HomeGeneralView(expiring: HomeMock.expiringWarranties, recent: HomeMock.recentReceipts)
        .background(Color.gray50)
}

#Preview("만료 예정 0건") {
    HomeGeneralView(expiring: [], recent: HomeMock.recentReceipts)
        .background(Color.gray50)
}
