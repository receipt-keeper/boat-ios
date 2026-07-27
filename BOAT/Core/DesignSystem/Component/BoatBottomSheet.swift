//
//  BoatBottomSheet.swift
//  BOAT
//
//  앱 공통 바텀시트 컨테이너.
//
//  iOS 26부터 시스템 `.sheet`는 화면 가장자리에서 띄워진 "플로팅 카드"로 렌더링되어
//  좌우/하단에 여백이 생기고 네 모서리가 모두 둥글어진다. 디자인 가이드는 좌우/하단이
//  화면에 꽉 차고 상단 두 모서리만 rounded_xl인 형태이고, Android도 그렇게 동작한다.
//  이 인셋을 끄는 공식 API가 없어, 시스템 시트 대신 직접 하단 카드를 그린다.
//
//  표시 방식은 앱에서 이미 쓰고 있는 패턴(BoatDialog / PhotoSourceSheet)과 동일하게
//  `fullScreenCover` + `.presentationBackground(.clear)` 위에 얹는다 —
//  단순 `.overlay`로 두면 MainTabView의 플로팅 하단 바보다 뒤에 깔린다.
//

import SwiftUI

extension View {
    /// 앱 공통 바텀시트를 띄운다. 시스템 `.sheet` 대신 사용한다.
    /// - Parameters:
    ///   - isPresented: 표시 여부
    ///   - onDismiss: 스크림(딤 배경)을 탭했을 때 호출. nil이면 스크림 탭으로 닫히지 않는다.
    func boatBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            BoatBottomSheetContainer(onDismiss: onDismiss) { content() }
                .presentationBackground(.clear)
        }
    }

    /// `Identifiable` 아이템 기반 버전.
    func boatBottomSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        fullScreenCover(item: item) { value in
            BoatBottomSheetContainer(onDismiss: onDismiss) { content(value) }
                .presentationBackground(.clear)
        }
    }
}

/// 딤 배경 + 하단에 붙는 흰 카드(상단 모서리만 둥금). 높이는 콘텐츠에 맞춰 자동 산정된다.
struct BoatBottomSheetContainer<Content: View>: View {

    var onDismiss: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss?() }

            content
                .frame(maxWidth: .infinity)
                // 카드 배경만 하단 안전영역까지 늘려 화면 끝에 붙이고, 콘텐츠 자체는
                // 홈 인디케이터에 가리지 않도록 안전영역 안쪽에 둔다.
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: .roundedXl,
                        topTrailingRadius: .roundedXl
                    )
                    .fill(Color.colorWhite)
                    .ignoresSafeArea(edges: .bottom)
                )
        }
    }
}
