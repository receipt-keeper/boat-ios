//
//  HomeLoadingView.swift
//  BOAT
//
//  홈 초기 API 로딩 중 표시되는 오버레이.
//  zero_preview.gif 무한 재생 + 안내 문구.
//

import SwiftUI

struct HomeLoadingView: View {

    var message: LocalizedStringKey = "home.loading"

    var body: some View {
        ZStack {
            Color.colorWhite

            VStack(spacing: 16) {
                GifImageView(name: "zero_preview")
                    .frame(width: 200, height: 200)

                Text(message)
                    .font(.pretendard(.medium, size: 16))
                    .foregroundStyle(Color.gray500)
            }
        }
    }
}

#Preview {
    HomeLoadingView()
}
