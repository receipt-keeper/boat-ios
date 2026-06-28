//
//  SearchView.swift
//  BOAT
//
//  영수증 검색 화면 — 기기명/메모 검색. Android SearchScreen 대응.
//

import SwiftUI

struct SearchView: View {

    let onBack: () -> Void

    @State private var query = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .background(Color.colorWhite)

            Color.gray50
                .ignoresSafeArea(edges: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray50)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            focused = true
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

            Button {
                hideKeyboard()
                // TODO: 검색 실행
            } label: {
                Image("icSearch")
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray900)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing20)
    }

    private var searchField: some View {
        HStack(spacing: .spacing8) {
            TextField(
                "",
                text: $query,
                prompt: Text("기기명 또는 메모를 검색해 보세요.")
                    .foregroundStyle(Color.gray400)
                    .font(.pretendard(.regular, size: 14))
            )
            .font(.pretendard(.regular, size: 14))
            .foregroundStyle(Color.gray900)
            .focused($focused)
            .submitLabel(.search)
            .onSubmit { hideKeyboard() }

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.gray400)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .spacing12)
        .frame(height: 40)
        .background(Color.gray100, in: RoundedRectangle(cornerRadius: .roundedFull))
    }

    private func hideKeyboard() {
        focused = false
    }
}

#Preview {
    SearchView(onBack: {})
}
