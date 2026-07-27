//
//  ImageViewerScreen.swift
//  BOAT
//
//  전체화면 이미지 뷰어 — 핀치 확대/축소(1~4배), 확대 중 팬, 더블탭 확대/원복, 좌우 스와이프 페이징,
//  단일 탭으로 상단 바(닫기 + N/전체) 토글. Android ImageViewerScreen 대응.
//  로컬(UIImage)/원격(ReceiptFile, 인증 필요) 이미지를 섞어서 표시할 수 있다.
//
//  확대/이동은 SwiftUI 제스처가 아니라 UIScrollView가 처리한다 — 사진 앱과 동일한 방식이다.
//  SwiftUI MagnifyGesture/DragGesture로 scale·offset을 @State에 반영하면 손가락이 움직이는
//  매 프레임마다 뷰 트리가 다시 계산되어 뚝뚝 끊긴다. UIScrollView는 확대·이동을 렌더 서버에서
//  처리하므로 SwiftUI 업데이트 없이 부드럽게 동작하고, 감속·고무줄 효과도 기본으로 따라온다.
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

// MARK: - 페이지 (확대/이동은 ZoomableScrollView가 담당)

private struct ZoomableImagePage: View {
    let item: ImageViewerItem
    var onSingleTap: () -> Void = {}

    var body: some View {
        ZoomableScrollView(onSingleTap: onSingleTap) {
            content
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
}

// MARK: - UIScrollView 기반 확대/이동 컨테이너

/// 콘텐츠를 UIScrollView에 얹어 네이티브 핀치 확대·팬·감속을 그대로 사용한다.
/// - 확대 중에만 bounce를 켜서, 축소 상태의 좌우 스와이프는 상위 TabView의 페이징으로 넘어간다.
/// - 더블탭: 탭한 지점을 중심으로 확대 / 확대 상태면 원복.
/// - 싱글탭: [onSingleTap] (상단 바 토글). 더블탭이 실패한 뒤에만 인식된다.
///
/// 콘텐츠를 제네릭이 아닌 AnyView로 담는 이유:
/// 제네릭 struct 안에 중첩된 Coordinator(= UIHostingController<Content> 보유)를 두면
/// Release 최적화(EarlyPerfInliner)에서 Coordinator.deinit을 인라이닝하다 Swift 6.3
/// 컴파일러가 크래시한다(Debug/시뮬레이터는 해당 패스를 돌지 않아 통과). 타입을 고정해
/// Coordinator를 비제네릭으로 만들면 이 경로를 타지 않는다. 페이지당 이미지 하나뿐이라
/// AnyView로 인한 비용은 무시할 수준이다.
private struct ZoomableScrollView: UIViewRepresentable {

    private let content: AnyView
    private let onSingleTap: () -> Void

    private static var maxZoom: CGFloat { 4 }
    private static var doubleTapZoom: CGFloat { 2.5 }

    init<C: View>(onSingleTap: @escaping () -> Void, @ViewBuilder content: () -> C) {
        self.content = AnyView(content())
        self.onSingleTap = onSingleTap
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = Self.maxZoom
        scrollView.bouncesZoom = true
        // 축소 상태에서는 bounce를 꺼야 좌우 스와이프가 TabView 페이징으로 전달된다.
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never

        let hosted = context.coordinator.hostingController.view!
        hosted.translatesAutoresizingMaskIntoConstraints = false
        hosted.backgroundColor = .clear
        scrollView.addSubview(hosted)
        NSLayoutConstraint.activate([
            hosted.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosted.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hosted.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosted.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            // 확대 전 콘텐츠는 항상 화면 크기와 동일 — 이래야 scaledToFit이 화면 기준으로 맞춰진다.
            hosted.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hosted.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSingleTap)
        )
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // 확대/이동 중에는 SwiftUI 업데이트가 발생하지 않으므로 여기서 프레임 단위 비용은 없다.
        context.coordinator.hostingController.rootView = content
        context.coordinator.onSingleTap = onSingleTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rootView: content, onSingleTap: onSingleTap, doubleTapZoom: Self.doubleTapZoom)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {

        let hostingController: UIHostingController<AnyView>
        var onSingleTap: () -> Void
        private let doubleTapZoom: CGFloat

        init(rootView: AnyView, onSingleTap: @escaping () -> Void, doubleTapZoom: CGFloat) {
            self.hostingController = UIHostingController(rootView: rootView)
            self.onSingleTap = onSingleTap
            self.doubleTapZoom = doubleTapZoom
            super.init()
            hostingController.view.backgroundColor = .clear
            // 세이프에어리어만큼 콘텐츠가 밀리지 않도록 — 뷰어는 전체화면으로 꽉 채운다.
            hostingController.safeAreaRegions = []
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // 확대 상태에서만 고무줄 효과를 허용한다(축소 상태에선 TabView 페이징 우선).
            scrollView.bounces = scrollView.zoomScale > scrollView.minimumZoomScale
        }

        @objc func handleSingleTap() {
            onSingleTap()
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }

            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
                return
            }

            // 탭한 지점이 화면 중앙에 오도록 확대한다.
            let point = gesture.location(in: hostingController.view)
            let width = scrollView.bounds.width / doubleTapZoom
            let height = scrollView.bounds.height / doubleTapZoom
            let rect = CGRect(
                x: point.x - width / 2,
                y: point.y - height / 2,
                width: width,
                height: height
            )
            scrollView.zoom(to: rect, animated: true)
        }
    }
}
