//
//  ImageViewerScreen.swift
//  BOAT
//
//  전체화면 이미지 뷰어 — 핀치 확대/축소(1~4배), 확대 중 팬, 더블탭 리셋, 좌우 스와이프 페이징,
//  단일 탭으로 상단 바(닫기 + N/전체) 토글. Android ImageViewerScreen 대응.
//  로컬(UIImage)/원격(ReceiptFile, 인증 필요) 이미지를 섞어서 표시할 수 있다.
//

import SwiftUI

enum ImageViewerItem {
    case local(UIImage)
    case remote(ReceiptFile)
}

struct ImageViewerScreen: View {
    let items: [ImageViewerItem]
    var initialIndex: Int = 0
    let onClose: () -> Void

    @State private var currentIndex: Int
    @State private var showTopBar = true

    init(items: [ImageViewerItem], initialIndex: Int = 0, onClose: @escaping () -> Void) {
        self.items = items
        self.initialIndex = initialIndex
        self.onClose = onClose
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ZoomableImagePage(item: item, onSingleTap: {
                        withAnimation(.easeInOut(duration: 0.2)) { showTopBar.toggle() }
                    })
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            if showTopBar {
                topBar
                    .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.colorWhite)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(currentIndex + 1) / \(items.count)")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.colorWhite)
                .tracking(2)
        }
        .padding(.horizontal, .spacing20)
        .padding(.vertical, .spacing16)
        .padding(.bottom, .spacing16)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - 핀치 줌 + 팬 + 더블탭 리셋 페이지

private struct ZoomableImagePage: View {
    let item: ImageViewerItem
    var onSingleTap: () -> Void = {}

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            content
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .contentShape(Rectangle())
                .gesture(magnifyGesture)
                // 확대 상태(scale > 1)일 때만 팬 제스처를 소비 — 그 외엔 TabView 스와이프가 우선하도록 비활성화.
                .gesture(dragGesture(in: geo.size), including: scale > 1 ? .all : .subviews)
                .onTapGesture(count: 2) { resetZoom() }
                .onTapGesture(count: 1) { onSingleTap() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item {
        case .local(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        case .remote(let file):
            AuthenticatedImage(contentPath: file.contentPath, contentMode: .fit)
        }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(lastScale * value.magnification, 1), 4)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 {
                    withAnimation(.easeInOut(duration: 0.2)) { offset = .zero }
                    lastOffset = .zero
                }
            }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                let maxX = (size.width * (scale - 1)) / 2
                let maxY = (size.height * (scale - 1)) / 2
                let newX = lastOffset.width + value.translation.width
                let newY = lastOffset.height + value.translation.height
                offset = CGSize(
                    width: min(max(newX, -maxX), maxX),
                    height: min(max(newY, -maxY), maxY)
                )
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = 1
            offset = .zero
        }
        lastScale = 1
        lastOffset = .zero
    }
}
