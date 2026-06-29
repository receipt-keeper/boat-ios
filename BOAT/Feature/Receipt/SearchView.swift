//
//  SearchView.swift
//  BOAT
//
//  영수증 검색 화면 — 제품명/메모 검색. Android SearchScreen 대응.
//

import SwiftUI

struct SearchView: View {

    let onBack: () -> Void

    @State private var query = ""
    @FocusState private var focused: Bool
    @State private var showRegister = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
                // 상태바 영역까지 흰 배경으로 덮음
                .background(Color.colorWhite.ignoresSafeArea(edges: .top))

            if query.isEmpty {
                Color.gray50
                    .ignoresSafeArea(edges: .bottom)
            } else {
                emptyResultView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray50)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            focused = true
        }
        .fullScreenCover(isPresented: $showRegister) {
            ReceiptRegisterView(onBack: { showRegister = false })
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: .spacing8) {
            Button(action: onBack) {
                Image("icChevronLeft")
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray900)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            searchField
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    private var searchField: some View {
        HStack(spacing: .spacing8) {
            TextField(
                "",
                text: $query,
                prompt: Text("search.placeholder")
                    .foregroundStyle(Color.gray400)
                    .font(.pretendard(.regular, size: 14))
            )
            .font(.pretendard(.regular, size: 14))
            .foregroundStyle(Color.gray900)
            .focused($focused)
            .submitLabel(.search)
            .onSubmit { focused = false }

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.gray400)
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: query.isEmpty)
        .padding(.horizontal, .spacing12)
        .frame(height: 40)
        .background(Color.gray100, in: RoundedRectangle(cornerRadius: .roundedFull))
    }

    // MARK: - 검색 결과 없음

    private var emptyResultView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: .spacing12) {
                Text("search.empty.title")
                    .font(.pretendard(.bold, size: 18))
                    .foregroundStyle(Color.gray900)

                Text("search.empty.subtitle")
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color.gray500)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer().frame(height: .spacing24)

            Button {
                focused = false
                showRegister = true
            } label: {
                HStack(spacing: .spacing8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("search.empty.register")
                        .font(.pretendard(.semibold, size: 15))
                }
                .foregroundStyle(Color.colorWhite)
                .padding(.horizontal, .spacing24)
                .padding(.vertical, .spacing16)
                .background(Color.brandPrimary, in: RoundedRectangle(cornerRadius: .roundedXl))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray50)
    }
}

#Preview {
    SearchView(onBack: {})
}
