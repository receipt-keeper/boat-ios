//
//  FileRepository.swift
//  BOAT
//
//  이미지 파일 업로드. POST /api/v1/files
//

import UIKit
import Alamofire

// MARK: - Model

struct UploadedFile: Decodable {
    let fileId: String
    let originalName: String
    let contentType: String
    let size: Int
    let contentPath: String
}

struct UploadedFileList: Decodable {
    let files: [UploadedFile]
}

// MARK: - Repository

@MainActor
final class FileRepository {
    static let shared = FileRepository()
    private init() {}

    /// POST /api/v1/files — UIImage 목록을 multipart로 업로드.
    func uploadImages(_ images: [UIImage]) async throws -> [UploadedFile] {
        let result: UploadedFileList = try await APIClient.shared.uploadMultipart(
            path: "/api/v1/files",
            builder: { form in
                for (index, image) in images.enumerated() {
                    guard let data = image.jpegData(compressionQuality: 0.9) else { continue }
                    form.append(
                        data,
                        withName: "files",
                        fileName: "receipt-\(index + 1).jpg",
                        mimeType: "image/jpeg"
                    )
                }
            }
        )
        return result.files
    }

    /// GET {contentPath} — 첨부 파일(이미지) 원본 바이너리 조회. Authorization 자동 주입.
    func fetchContent(path: String) async throws -> Data {
        try await APIClient.shared.requestData(FileTarget.content(path: path))
    }
}
