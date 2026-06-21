//
//  NetworkLogger.swift
//  BOAT
//
//  Alamofire EventMonitor로 API 요청/응답을 Xcode 콘솔에 출력합니다.
//  Android의 OkHttp HttpLoggingInterceptor에 대응. DEBUG 빌드에서만 동작합니다.
//

import Foundation
import Alamofire

#if DEBUG
final class NetworkLogger: EventMonitor {

    let queue = DispatchQueue(label: "com.receipt-keeper.BOAT.networklogger")

    // 요청 시작
    func requestDidResume(_ request: Request) {
        guard let urlRequest = request.request else { return }
        let method = urlRequest.httpMethod ?? "?"
        let url = urlRequest.url?.absoluteString ?? "?"

        var lines = ["", "🟦 ───── REQUEST ─────", "➡️ [\(method)] \(url)"]
        if let headers = urlRequest.allHTTPHeaderFields, !headers.isEmpty {
            lines.append("  Headers: \(headers)")
        }
        if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            lines.append("  Body: \(bodyString)")
        }
        lines.append("─────────────────────")
        print(lines.joined(separator: "\n"))
    }

    // 응답 수신
    func request(_ request: DataRequest, didParseResponse response: DataResponse<Data?, AFError>) {
        let url = request.request?.url?.absoluteString ?? "?"
        let status = response.response?.statusCode ?? 0
        let emoji = (200..<300).contains(status) ? "✅" : "❌"

        var lines = ["", "🟩 ───── RESPONSE ────", "\(emoji) [\(status)] \(url)"]
        if let data = response.data, let bodyString = String(data: data, encoding: .utf8), !bodyString.isEmpty {
            lines.append("  Body: \(bodyString)")
        }
        if case let .failure(error) = response.result {
            lines.append("  Error: \(error.localizedDescription)")
        }
        lines.append("─────────────────────")
        print(lines.joined(separator: "\n"))
    }
}
#endif
