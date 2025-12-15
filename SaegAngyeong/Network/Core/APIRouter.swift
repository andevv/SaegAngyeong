//
//  APIRouter.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire
import Combine

// MARK: - Core Types

/// API 요청 시 필요한 멀티파트 파일 정의
struct UploadFile {
    let data: Data
    let fileName: String
    let mimeType: String
}

/// 실제로 어떤 형태의 요청을 보낼지 정의
enum APITask {
    case requestPlain
    case requestQuery(Parameters)
    case requestJSON(any Encodable)
    case uploadFiles([UploadFile])
}

/// 각 Endpoint가 채택해야 하는 공통 스펙
protocol APIEndpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var task: APITask { get }
    var requiresAuth: Bool { get }
    var additionalHeaders: HTTPHeaders { get }
}

extension APIEndpoint {
    var baseURL: URL {
            guard let url = URL(string: AppConfig.baseURL) else {
                fatalError("Invalid BASE_URL: \(AppConfig.baseURL)")
            }
            return url
        }
    var requiresAuth: Bool { false }
    var additionalHeaders: HTTPHeaders { HTTPHeaders() }
}

// MARK: - Router

/// Alamofire에서 사용할 URLRequestConvertible 구현체
struct APIRouter: URLRequestConvertible {
    let endpoint: APIEndpoint
    private let accessTokenProvider: () -> String?
    private let sesacKey: String

    init(
        endpoint: APIEndpoint,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String = AppConfig.apiKey
    ) {
        self.endpoint = endpoint
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
    }

    func asURLRequest() throws -> URLRequest {
        let trimmedPath = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        let url = endpoint.baseURL.appendingPathComponent(trimmedPath)

        var request = try URLRequest(url: url, method: endpoint.method)

        var headers = endpoint.additionalHeaders
        headers.add(name: "SeSACKey", value: sesacKey)

        if endpoint.requiresAuth, let token = accessTokenProvider() {
            headers.add(name: "Authorization", value: token)
            // 필요 시: "Bearer \(token)"
        }

        request.headers = headers

        switch endpoint.task {
        case .requestPlain, .uploadFiles:
            return request

        case .requestQuery(let parameters):
            return try URLEncoding.queryString.encode(request, with: parameters)

        case .requestJSON(let body):
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            request.headers.add(.contentType("application/json"))
            return request
        }
    }
}

// MARK: - Network Provider

/// Combine 기반 네트워크 추상화 계층
protocol NetworkProviding {
    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError>
    func request<T: Decodable>(_ type: T.Type, endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError>
    func requestVoid(_ endpoint: APIEndpoint) -> AnyPublisher<Void, NetworkError>
}

final class NetworkProvider: NetworkProviding {

    private let session: Session
    private let accessTokenProvider: () -> String?
    private let sesacKey: String

    init(
        session: Session = .default,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String = AppConfig.apiKey
    ) {
        self.session = session
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError> {
        request(T.self, endpoint: endpoint)
    }

    func request<T: Decodable>(_ type: T.Type, endpoint: APIEndpoint) -> AnyPublisher<T, NetworkError> {
        let router = APIRouter(
            endpoint: endpoint,
            accessTokenProvider: accessTokenProvider,
            sesacKey: sesacKey
        )

        switch endpoint.task {
        case .uploadFiles(let files):
            return upload(router: router, files: files)
                .publishDecodable(type: T.self)
                .value()
                .mapError { NetworkError($0) }
                .eraseToAnyPublisher()

        default:
            return session.request(router)
                .validate()
                .publishDecodable(type: T.self)
                .value()
                .mapError { NetworkError($0) }
                .eraseToAnyPublisher()
        }
    }

    func requestVoid(_ endpoint: APIEndpoint) -> AnyPublisher<Void, NetworkError> {
        let publisher: AnyPublisher<EmptyResponse, NetworkError> = request(endpoint)
        return publisher
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    private func upload(
        router: APIRouter,
        files: [UploadFile]
    ) -> DataRequest {
        session.upload(
            multipartFormData: { formData in
                files.forEach { file in
                    formData.append(
                        file.data,
                        withName: "files",
                        fileName: file.fileName,
                        mimeType: file.mimeType
                    )
                }
            },
            with: router
        )
        .validate()
    }
}

// MARK: - Helpers

func compactQuery(_ parameters: [String: Any?]) -> Parameters {
    parameters.reduce(into: Parameters()) { partialResult, entry in
        if let value = entry.value {
            partialResult[entry.key] = value
        }
    }
}

/// 빈 응답을 표현할 때 사용
struct EmptyResponse: Decodable {}

struct AnyEncodable: Encodable {
    private let encodable: any Encodable

    init(_ encodable: any Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

enum NetworkError: Error {
    case invalidURL
    case unauthorized
    case server(statusCode: Int, message: String?)
    case decoding(Error)
    case underlying(Error)

    init(_ error: AFError) {
        if let responseCode = error.responseCode {
            if responseCode == 401 {
                self = .unauthorized
            } else {
                self = .server(statusCode: responseCode, message: error.errorDescription)
            }
        } else if case .responseSerializationFailed(let reason) = error {
            switch reason {
            case .decodingFailed(let decodingError):
                self = .decoding(decodingError)
            default:
                self = .underlying(error)
            }
        } else {
            self = .underlying(error)
        }
    }
}
