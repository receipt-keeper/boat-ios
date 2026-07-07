//
//  FileTarget.swift
//  BOAT
//
//  파일 원본 조회. GET {contentPath} (예: /api/v1/files/{fileId}/content)
//

import Foundation
import Alamofire

enum FileTarget: TargetType {
    case content(path: String)

    var path: String {
        switch self {
        case .content(let path):
            return path
        }
    }

    var method: HTTPMethod { .get }

    var task: RequestTask { .plain }
}
