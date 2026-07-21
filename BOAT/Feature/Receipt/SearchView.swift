//
//  SearchView.swift
//  BOAT
//
//  영수증 검색 화면 — 제품명/메모 검색. Android SearchScreen 대응.
//  입력 디바운스 후 GET /api/v1/receipts?q= 조회. 결과 있으면 카운트+목록(무한 스크롤),
//  없으면 등록 유도 화면.
//

import SwiftUI

struct SearchView: View {

    let onBack: () -> Void
    /// 상세에서 영수증 삭제 시 호출 — 검색 화면 자체를 닫고 목록 탭으로 이동시킨다(상위에서 처리).
    var onDeleted: () -> Void = {}

    @State private var query = ""
    @FocusState private var focused: Bool
    @State private var showRegister = false
    @State private var detailReceipt: Receipt?

    @State private var viewModel = ReceiptListViewModel()
    @State private var isDebouncing = false
    @State private var searchTask: Task<Void, Never>?
    @State private var toast = BoatToastState()

    private static let debounce: Duration = .milliseconds(350)

    var body: some View {
        VStack(spacing: 0) {
            topBar
                // 본문과 동일한 배경 — 상태바 영역까지 이어지도록 확장
                .background(Color.gray50.ignoresSafeArea(edges: .top))

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray50)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            focused = true
        }
        .onChange(of: query) { _, newValue in
            if newValue.count > 100 {
                query = String(newValue.prefix(100))
                return
            }
            searchTask?.cancel()
            let trimmed = newValue.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else {
                isDebouncing = false
                return
            }
            isDebouncing = true
            searchTask = Task {
                try? await Task.sleep(for: Self.debounce)
                guard !Task.isCancelled else { return }
                await viewModel.reload(tab: .all, sort: .default, filter: .all, q: trimmed)
                guard !Task.isCancelled else { return }
                isDebouncing = false
            }
        }
        .fullScreenCover(isPresented: $showRegister) {
            ReceiptRegisterView(onBack: { showRegister = false })
        }
        .fullScreenCover(item: $detailReceipt) { receipt in
            ReceiptDetailView(
                receiptId: receipt.receiptId,
                onBack: { detailReceipt = nil },
                // 검색 결과 화면은 삭제를 반영해 다시 그리지 않으므로, 상세를 닫는 것에 그치지 않고
                // 검색 화면 자체를 닫은 뒤 (갱신된) 목록 탭으로 이동시킨다.
                onDeleted: {
                    detailReceipt = nil
                    toast.show(String(localized: "detail.deleted_toast"), type: .info)
                    onBack()
                    onDeleted()
                }
            )
        }
        .boatToastHost(toast)
    }

    // MARK: - 콘텐츠 분기

    @ViewBuilder
    private var content: some View {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            Color.gray50.ignoresSafeArea(edges: .bottom)
        } else if isDebouncing || viewModel.isLoading {
            // 입력 중(디바운스 대기) / 조회 중 — 이전 결과를 보여주지 않고 빈 화면 유지
            Color.gray50.ignoresSafeArea(edges: .bottom)
        } else if viewModel.receipts.isEmpty {
            emptyResultView
        } else {
            resultListView
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

            if query.isEmpty {
                Image("icSearch")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.gray400)
            } else {
                Button { query = "" } label: {
                    Image("icon_close_search")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: query.isEmpty)
        .padding(.horizontal, .spacing16)
        .padding(.vertical, 8)
        .background(Color.colorWhite, in: RoundedRectangle(cornerRadius: .roundedLg))
        .overlay(
            RoundedRectangle(cornerRadius: .roundedLg)
                .stroke(Color.gray300, lineWidth: 1)
        )
    }

    // MARK: - 검색 결과 (카운트 + 목록)

    private var resultListView: some View {
        VStack(spacing: 0) {
            countRow

            ScrollView {
                LazyVStack(spacing: .spacing12) {
                    ForEach(viewModel.receipts) { receipt in
                        ReceiptCard(receipt: receipt, showKebab: false, thumbnailSize: 50, onTap: {
                            detailReceipt = receipt
                        })
                        .task { await viewModel.loadMoreIfNeeded(currentItem: receipt) }
                    }

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .tint(Color.brandPrimary)
                            .padding(.vertical, .spacing16)
                    }
                }
                .padding(.horizontal, .spacing20)
                .padding(.top, .spacing4)
                .padding(.bottom, .spacing24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var countRow: some View {
        HStack(spacing: .spacing8) {
            Text("receipt.filter.all")
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray600)
            Text("|")
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(Color.gray300)
            Text("\(viewModel.totalCount)")
                .font(.pretendard(.bold, size: 14))
                .foregroundStyle(Color.brandPrimary)
            Spacer()
        }
        .padding(.horizontal, .spacing20)
        .padding(.vertical, .spacing12)
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
