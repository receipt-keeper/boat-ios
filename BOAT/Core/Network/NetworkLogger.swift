//
//  NetworkLogger.swift
//  BOAT
//
//  API 요청/응답을 Xcode 콘솔에 출력합니다.
//  APIClient에서 응답 수신 직후 직접 호출합니다. DEBUG 빌드에서만 동작합니다.
//

import Foundation
import Alamofire

#if DEBUG
enum NetworkLogger {

    /// 요청 URLRequest + 응답을 한 번에 출력
    static func log(_ response: AFDataResponse<Data>) {
        let request = response.request
        let method = request?.httpMethod ?? "?"
        let url = request?.url?.absoluteString ?? "?"
        let status = response.response?.statusCode ?? 0
        let emoji = (200..<300).contains(status) ? "✅" : "❌"

        var lines = ["", "🟦──────── API ────────"]
        lines.append("➡️ [\(method)] \(url)")
        if let body = request?.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            lines.append("  ▸ Request: \(bodyString)")
        }
        lines.append("\(emoji) [\(status)]")
        if let data = response.data, let bodyString = String(data: data, encoding: .utf8), !bodyString.isEmpty {
            lines.append("  ▸ Response: \(bodyString)")
        }
        if case let .failure(error) = response.result {
            lines.append("  ⚠️ Error: \(error.localizedDescription)")
        }
        lines.append("──────────────────────")
        print(lines.joined(separator: "\n"))
    }
}
#endif
