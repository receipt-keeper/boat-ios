//
//  AuthenticatedImage.swift
//  BOAT
//
//  Authorization 토큰이 필요한 파일(첨부 영수증 원본 등)을 contentPath로 비동기 로드.
//  메모리 캐시(NSCache)로 같은 파일 재조회를 방지한다.
//

import SwiftUI

struct AuthenticatedImage: View {
    let contentPath: String

    @State private var image: UIImage?
    @State private var failed = false

    private static let cache = NSCache<NSString, UIImage>()

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if failed {
                Image(systemName: "photo")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.gray300)
            } else {
                ProgressView()
                    .tint(Color.brandPrimary)
            }
        }
        .task(id: contentPath) { await load() }
    }

    private func load() async {
        let key = contentPath as NSString
        if let cached = Self.cache.object(forKey: key) {
            image = cached
            return
        }
        do {
            let data = try await FileRepository.shared.fetchContent(path: contentPath)
            guard let loaded = UIImage(data: data) else {
                failed = true
                return
            }
            Self.cache.setObject(loaded, forKey: key)
            image = loaded
        } catch {
            failed = true
        }
    }
}
