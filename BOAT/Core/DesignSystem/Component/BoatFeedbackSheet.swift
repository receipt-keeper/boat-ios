//
//  BoatFeedbackSheet.swift
//  BOAT
//
//  서비스 만족도 피드백 바텀시트 — 별점(1~5) + 선택 의견(최대 100자).
//  Android UserFeedbackBottomSheet 대응.
//

import SwiftUI

struct BoatFeedbackSheet: View {
    let onDismiss: () -> Void
    let onNext: () -> Void
    let onSubmit: (Int, String) -> Void
    /// 실측 콘텐츠 높이를 알려준다 — 별점 선택 시 의견 입력란이 펼쳐지며 커지는 실제 높이에
    /// 맞춰 호출부(presentationDetents)가 시트 높이를 그때그때 갱신하도록 한다. 고정값 금지.
    var onHeightChange: (CGFloat) -> Void = { _ in }

    @State private var rating = 0
    @State private var comment = ""

    private static let commentLimit = 100

    var body: some View {
        VStack(spacing: 0) {
            closeButton

            Text("feedback.title")
                .font(.pretendard(.bold, size: 20))
                .foregroundStyle(Color.gray900)

            Spacer().frame(height: .spacing12)

            Text("feedback.subtitle")
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(Color.gray600)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: .spacing32)

            starRow

            if rating > 0 {
                Spacer().frame(height: .spacing32)
                commentField
                    .padding(.horizontal, .spacing24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer().frame(height: .spacing40)

            buttons
                .padding(.horizontal, .spacing24)
        }
        .padding(.bottom, .spacing24)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.height, initial: true) { _, newHeight in
                        onHeightChange(newHeight)
                    }
            }
        )
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.gray900)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing, .spacing12)
        .padding(.top, .spacing8)
    }

    private var starRow: some View {
        HStack(spacing: .spacing8) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { rating = index }
                } label: {
                    Image(index <= rating ? "icStarOn" : "icStarOff")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var commentField: some View {
        ZStack(alignment: .topLeading) {
            if comment.isEmpty {
                Text("feedback.placeholder")
                    .font(.pretendard(.regular, size: 15))
                    .foregroundStyle(Color.gray400)
                    .lineSpacing(4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
            }
            TextEditor(text: Binding(
                get: { comment },
                set: { comment = String($0.prefix(Self.commentLimit)) }
            ))
            .font(.pretendard(.regular, size: 15))
            .foregroundStyle(Color.gray900)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .padding(.bottom, 20) // 우하단 글자 수 카운터와 겹치지 않도록
            .frame(height: 160)

            Text("feedback.counter \(comment.count)")
                .font(.pretendard(.regular, size: 12))
                .foregroundStyle(Color.gray400)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .overlay(
            RoundedRectangle(cornerRadius: .roundedLg)
                .stroke(Color.gray200, lineWidth: 1)
        )
    }

    private var buttons: some View {
        HStack(spacing: .spacing12) {
            Button(action: onNext) {
                Text("feedback.next")
                    .font(.pretendard(.bold, size: 16))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedXl))
                    .overlay(
                        RoundedRectangle(cornerRadius: .roundedXl)
                            .stroke(Color.brandPrimary, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button {
                onSubmit(rating, comment)
            } label: {
                Text("feedback.submit")
                    .font(.pretendard(.bold, size: 16))
                    .foregroundStyle(rating > 0 ? Color.colorWhite : Color.gray500)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        rating > 0 ? Color.brandPrimary : Color.gray200,
                        in: RoundedRectangle(cornerRadius: .roundedXl)
                    )
            }
            .buttonStyle(.plain)
            .disabled(rating == 0)
        }
    }
}

#Preview {
    BoatFeedbackSheet(onDismiss: {}, onNext: {}, onSubmit: { _, _ in })
        .background(Color.colorWhite)
}
