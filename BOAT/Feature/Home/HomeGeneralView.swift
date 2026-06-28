//
//  HomeGeneralView.swift
//  BOAT
//
//  홈 일반 콘텐츠 — AS 만료 예정(가로형 카드) + 최근 등록 영수증(세로형) + 더보기.
//  Android HomeGeneralContent 대응.
//

import SwiftUI

struct HomeGeneralView: View {

    let expiring: [ExpiringWarranty]
    let recent: [RecentReceipt]
    var onExpiringMore: () -> Void = {}
    var onRecentMore: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ── AS 만료 예정 헤더 ──
                Spacer().frame(height: .spacing16)
                expiringHeader
                    .padding(.horizontal, .spacing20)

                Spacer().frame(height: .spacing16)

                // 가로 스크롤 카드 (D-day 뱃지가 위로 겹치므로 상단 여유 확보)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacing16) {
                        ForEach(expiring) { item in
                            ExpiringWarrantyCard(item: item)
                        }
                    }
                    .padding(.horizontal, .spacing20)
                }

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
                    }
                    Spacer().frame(height: .spacing4)
                    moreButton
                }
                .padding(.horizontal, .spacing20)

                Spacer().frame(height: .spacing16)
            }
        }
    }

    // MARK: - AS 만료 예정 헤더

    private var expiringHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("home.expiring_caption")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundStyle(Color.gray500)
                HStack(spacing: 6) {
                    Text("home.expiring_title")
                        .font(.pretendard(.bold, size: 20))
                        .foregroundStyle(Color.gray900)
                    Text("home.expiring_count \(expiring.count)")
                        .font(.pretendard(.bold, size: 20))
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            Spacer()
            Button(action: onExpiringMore) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.gray400)
            }
            .buttonStyle(.plain)
        }
    }

    private var moreButton: some View {
        Button(action: onRecentMore) {
            Text("home.more")
                .font(.pretendard(.medium, size: 15))
                .foregroundStyle(Color.gray600)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.gray200, in: RoundedRectangle(cornerRadius: .roundedXl))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AS 만료 예정 가로형 카드 (D-day 뱃지 겹침)

private struct ExpiringWarrantyCard: View {
    let item: ExpiringWarranty

    private var cardWidth: CGFloat { UIScreen.main.bounds.width - 52 }
    private let badgeHeight: CGFloat = 32

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 카드 본문
            HStack(alignment: .top, spacing: .spacing16) {
                thumbnail
                infoColumn
            }
            .padding(20)
            .frame(width: cardWidth)
            .background(Color.brandSenary, in: RoundedRectangle(cornerRadius: .rounded2xl))
            .overlay(
                RoundedRectangle(cornerRadius: .rounded2xl)
                    .stroke(Color.brandPrimary, lineWidth: 1)
            )
            .padding(.top, badgeHeight / 2)

            // D-day 뱃지 — 우측 상단 모서리에 겹침
            Text("home.dday \(item.dDay)")
                .font(.pretendard(.bold, size: 14))
                .foregroundStyle(Color.colorWhite)
                .frame(height: badgeHeight)
                .padding(.horizontal, .spacing16)
                .background(Color.gray900, in: Capsule())
                .padding(.trailing, 24)
        }
        .frame(width: cardWidth)
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: .rounded2xl)
            .fill(Color.colorWhite)
            .frame(width: 88, height: 88)
            .overlay {
                if let name = item.localImageName {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.gray400)
                }
            }
    }

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(item.productName)
                .font(.pretendard(.bold, size: 18))
                .foregroundStyle(Color.gray900)
                .lineLimit(1)

            Spacer().frame(height: 14)

            VStack(alignment: .leading, spacing: 6) {
                labelValue("home.label.vendor", item.vendor)
                labelValue("home.label.purchase", item.purchaseDate)
            }

            Spacer().frame(height: 16)

            HStack(spacing: 8) {
                Text("home.label.warranty")
                    .font(.pretendard(.medium, size: 12))
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.colorWhite, in: Capsule())
                Text(item.warrantyUntil)
                    .font(.pretendard(.medium, size: 15))
                    .foregroundStyle(Color.gray900)
                    .lineLimit(1)
            }
        }
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

// MARK: - 최근 등록 영수증 세로형 아이템

private struct RecentReceiptItem: View {
    let item: RecentReceipt

    var body: some View {
        HStack(spacing: .spacing12) {
            RoundedRectangle(cornerRadius: .roundedXl)
                .fill(Color.brandSenary)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.brandPrimary.opacity(0.4))
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.productName)
                        .font(.pretendard(.bold, size: 15))
                        .foregroundStyle(Color.gray900)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("home.days_ago \(item.daysAgo)")
                        .font(.pretendard(.regular, size: 12))
                        .foregroundStyle(Color.gray400)
                }
                HStack(spacing: 0) {
                    Text("home.label.purchase")
                        .font(.pretendard(.regular, size: 13))
                        .foregroundStyle(Color.gray500)
                    Text("  |  ")
                        .font(.pretendard(.regular, size: 13))
                        .foregroundStyle(Color.gray400)
                    Text(item.purchaseDate)
                        .font(.pretendard(.regular, size: 13))
                        .foregroundStyle(Color.gray500)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .rounded2xl))
    }
}

#Preview {
    HomeGeneralView(expiring: HomeMock.expiringWarranties, recent: HomeMock.recentReceipts)
        .background(Color.gray50)
}
