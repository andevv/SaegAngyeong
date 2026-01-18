//
//  NetworkLogger.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Alamofire

/// 네트워크 요청/응답 로깅
final class NetworkLogger: EventMonitor {
    let queue = DispatchQueue(label: "com.saegangyeong.networklogger")

    func requestDidResume(_ request: Request) {
        guard let urlRequest = request.request else { return }
        let method = urlRequest.httpMethod ?? ""
        let url = urlRequest.url?.absoluteString ?? ""
        let headers = urlRequest.allHTTPHeaderFields ?? [:]
        let bodyString: String = {
            guard let data = urlRequest.httpBody else { return "" }
            return String(data: data, encoding: .utf8) ?? "\(data)"
        }()
        AppLogger.debug("➡️ [REQUEST] \(method) \(url)\nHeaders: \(headers)\nBody: \(bodyString)")
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        let url = request.request?.url?.absoluteString ?? ""
        let status = response.response?.statusCode ?? 0
        let dataString: String = {
            guard let data = response.data else { return "" }
            return String(data: data, encoding: .utf8) ?? "\(data)"
        }()
        if let error = response.error {
            AppLogger.debug("⛔️ [RESPONSE] \(status) \(url)\nError: \(error)\nBody: \(dataString)")
        } else {
            AppLogger.debug("✅ [RESPONSE] \(status) \(url)\nBody: \(dataString)")
        }
    }
}
