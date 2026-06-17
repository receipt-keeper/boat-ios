//
//  TargetType.swift
//  BOAT
//
//  Retrofit의 `interface ApiService { @GET(...) }` 선언부에 대응하는 프로토콜입니다.
//  기능별로 enum을 만들어 이 프로토콜을 채택하면, 각 case가 하나의 엔드포인트가 됩니다.
//
//  예시:
//  enum AuthTarget: TargetType {
//      case login(idToken: String)
//      case withdraw
//
//      var path: String {
//          switch self {
//          case .login:    return "/auth/login"
//          case .withdraw: return "/auth/withdraw"
//          }
//      }
//      var method: HTTPMethod {
//          switch self {
//          case .login:    return .post
//          case .withdraw: return .delete
//          }
//      }
//      var task: RequestTask {
//          switch self {
//          case .login(let idToken): return .body(["idToken": idToken])
//          case .withdraw:           return .plain
//          }
//      }
//  }
//

import Foundation
import Alamofire

/// 요청에 어떤 파라미터를 어떤 방식으로 실을지 정의합니다.
enum RequestTask {
    /// 파라미터 없음
    case plain
    /// URL 쿼리스트링 (주로 GET)
    case query([String: Any])
    /// JSON 바디 (주로 POST/PUT)
    case body([String: Any])
}

protocol TargetType: URLRequestConvertible {
    /// 스킴+호스트. 기본 구현으로 BaseURL을 사용하므로 보통 재정의 불필요.
    var baseURL: URL { get }
    /// "/auth/login" 처럼 baseURL 뒤에 붙는 경로
    var path: String { get }
    /// GET / POST / PUT / DELETE
    var method: HTTPMethod { get }
    /// 파라미터 적재 방식
    var task: RequestTask { get }
    /// 엔드포인트별 추가 헤더 (없으면 nil)
    var headers: HTTPHeaders? { get }
}

extension TargetType {

    var baseURL: URL { BaseURL.current }

    var headers: HTTPHeaders? {
        ["Content-Type": "application/json"]
    }

    /// TargetType을 실제 URLRequest로 변환합니다. (Alamofire가 내부적으로 호출)
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = try URLRequest(url: url, method: method, headers: headers)

        switch task {
        case .plain:
            break
        case .query(let parameters):
            request = try URLEncoding.queryString.encode(request, with: parameters)
        case .body(let parameters):
            request = try JSONEncoding.default.encode(request, with: parameters)
        }

        return request
    }
}
