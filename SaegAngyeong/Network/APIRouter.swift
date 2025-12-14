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

// MARK: - Endpoints

enum CommonAPI: APIEndpoint {
    case health

    var path: String { "common" }
    var method: HTTPMethod { .get }
    var task: APITask { .requestPlain }
}

enum AuthAPI: APIEndpoint {
    case refresh(refreshToken: String)

    var path: String { "v1/auth/refresh" }
    var method: HTTPMethod { .get }
    var task: APITask { .requestPlain }
    var requiresAuth: Bool { true }

    var additionalHeaders: HTTPHeaders {
        switch self {
        case .refresh(let refreshToken):
            return HTTPHeaders([HTTPHeader(name: "RefreshToken", value: refreshToken)])
        }
    }
}

enum UserAPI: APIEndpoint {
    case validateEmail(body: any Encodable)
    case join(body: any Encodable)
    case login(body: any Encodable)
    case loginKakao(body: any Encodable)
    case loginApple(body: any Encodable)
    case logout
    case updateDeviceToken(body: any Encodable)
    case fetchProfile(userID: String)
    case uploadProfileImage(files: [UploadFile])
    case myProfile
    case updateMyProfile(body: any Encodable)
    case search(nick: String?)
    case todayAuthor

    var path: String {
        switch self {
        case .validateEmail:
            return "v1/users/validation/email"
        case .join:
            return "v1/users/join"
        case .login:
            return "v1/users/login"
        case .loginKakao:
            return "v1/users/login/kakao"
        case .loginApple:
            return "v1/users/login/apple"
        case .logout:
            return "v1/users/logout"
        case .updateDeviceToken:
            return "v1/users/deviceToken"
        case .fetchProfile(let userID):
            return "v1/users/\(userID)/profile"
        case .uploadProfileImage:
            return "v1/users/profile/image"
        case .myProfile, .updateMyProfile:
            return "v1/users/me/profile"
        case .search:
            return "v1/users/search"
        case .todayAuthor:
            return "v1/users/today-author"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .validateEmail, .join, .login, .loginKakao, .loginApple, .logout, .uploadProfileImage:
            return .post
        case .updateDeviceToken:
            return .put
        case .fetchProfile, .myProfile, .search, .todayAuthor:
            return .get
        case .updateMyProfile:
            return .put
        }
    }

    var task: APITask {
        switch self {
        case .validateEmail(let body),
             .join(let body),
             .login(let body),
             .loginKakao(let body),
             .loginApple(let body),
             .updateMyProfile(let body),
             .updateDeviceToken(let body):
            return .requestJSON(body)

        case .logout, .myProfile, .fetchProfile, .todayAuthor:
            return .requestPlain

        case .uploadProfileImage(let files):
            return .uploadFiles(files)

        case .search(let nick):
            return .requestQuery(compactQuery([
                "nick": nick
            ]))
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .validateEmail, .join, .login, .loginKakao, .loginApple:
            return false
        default:
            return true
        }
    }
}

enum FilterAPI: APIEndpoint {
    case uploadFiles(files: [UploadFile])
    case create(body: any Encodable)
    case list(next: String?, limit: Int?, category: String?, orderBy: String?)
    case detail(id: String)
    case update(id: String, body: any Encodable)
    case delete(id: String)
    case createComment(filterID: String, body: any Encodable)
    case updateComment(filterID: String, commentID: String, body: any Encodable)
    case deleteComment(filterID: String, commentID: String)
    case like(filterID: String, body: any Encodable)
    case userFilters(userID: String, next: String?, limit: Int?, category: String?)
    case likedFilters(category: String?, next: String?, limit: Int?)
    case hotTrend
    case todayFilter

    var path: String {
        switch self {
        case .uploadFiles:
            return "v1/filters/files"
        case .create, .list:
            return "v1/filters"
        case .detail(let id), .update(let id, _), .delete(let id):
            return "v1/filters/\(id)"
        case .createComment(let id, _):
            return "v1/filters/\(id)/comments"
        case .updateComment(let id, let commentID, _),
             .deleteComment(let id, let commentID):
            return "v1/filters/\(id)/comments/\(commentID)"
        case .like(let id, _):
            return "v1/filters/\(id)/like"
        case .userFilters(let userID, _, _, _):
            return "v1/filters/users/\(userID)"
        case .likedFilters:
            return "v1/filters/likes/me"
        case .hotTrend:
            return "v1/filters/hot-trend"
        case .todayFilter:
            return "v1/filters/today-filter"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create, .uploadFiles, .createComment, .like:
            return .post
        case .list, .detail, .userFilters, .likedFilters, .hotTrend, .todayFilter:
            return .get
        case .update, .updateComment:
            return .put
        case .delete, .deleteComment:
            return .delete
        }
    }

    var task: APITask {
        switch self {
        case .uploadFiles(let files):
            return .uploadFiles(files)

        case .create(let body),
             .update(_, let body),
             .createComment(_, let body),
             .updateComment(_, _, let body),
             .like(_, let body):
            return .requestJSON(body)

        case .list(let next, let limit, let category, let orderBy):
            return .requestQuery(compactQuery([
                "next": next,
                "limit": limit,
                "category": category,
                "order_by": orderBy
            ]))

        case .userFilters(_, let next, let limit, let category):
            return .requestQuery(compactQuery([
                "next": next,
                "limit": limit,
                "category": category
            ]))

        case .likedFilters(let category, let next, let limit):
            return .requestQuery(compactQuery([
                "category": category,
                "next": next,
                "limit": limit
            ]))

        case .detail, .delete, .deleteComment, .hotTrend, .todayFilter:
            return .requestPlain
        }
    }

    var requiresAuth: Bool { true }
}

enum PostAPI: APIEndpoint {
    case uploadFiles(files: [UploadFile])
    case create(body: any Encodable)
    case geolocation(category: String?, longitude: Double?, latitude: Double?, maxDistance: Double?, limit: Int?, next: String?, orderBy: String?)
    case search(title: String?)
    case detail(id: String)
    case update(id: String, body: any Encodable)
    case delete(id: String)
    case like(postID: String, body: any Encodable)
    case userPosts(userID: String, category: String?, limit: Int?, next: String?)
    case likedPosts(category: String?, next: String?, limit: String?)
    case createComment(postID: String, body: any Encodable)
    case updateComment(postID: String, commentID: String, body: any Encodable)
    case deleteComment(postID: String, commentID: String)

    var path: String {
        switch self {
        case .uploadFiles:
            return "v1/posts/files"
        case .create:
            return "v1/posts"
        case .geolocation:
            return "v1/posts/geolocation"
        case .search:
            return "v1/posts/search"
        case .detail(let id), .update(let id, _), .delete(let id):
            return "v1/posts/\(id)"
        case .like(let id, _):
            return "v1/posts/\(id)/like"
        case .userPosts(let userID, _, _, _):
            return "v1/posts/users/\(userID)"
        case .likedPosts:
            return "v1/posts/likes/me"
        case .createComment(let id, _):
            return "v1/posts/\(id)/comments"
        case .updateComment(let postID, let commentID, _),
             .deleteComment(let postID, let commentID):
            return "v1/posts/\(postID)/comments/\(commentID)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .uploadFiles, .create, .like, .createComment:
            return .post
        case .geolocation, .search, .detail, .userPosts, .likedPosts:
            return .get
        case .update, .updateComment:
            return .put
        case .delete, .deleteComment:
            return .delete
        }
    }

    var task: APITask {
        switch self {
        case .uploadFiles(let files):
            return .uploadFiles(files)

        case .create(let body),
             .update(_, let body),
             .like(_, let body),
             .createComment(_, let body),
             .updateComment(_, _, let body):
            return .requestJSON(body)

        case .geolocation(let category, let longitude, let latitude, let maxDistance, let limit, let next, let orderBy):
            return .requestQuery(compactQuery([
                "category": category,
                "longitude": longitude,
                "latitude": latitude,
                "maxDistance": maxDistance,
                "limit": limit,
                "next": next,
                "order_by": orderBy
            ]))

        case .search(let title):
            return .requestQuery(compactQuery([
                "title": title
            ]))

        case .userPosts(_, let category, let limit, let next):
            return .requestQuery(compactQuery([
                "category": category,
                "limit": limit,
                "next": next
            ]))

        case .likedPosts(let category, let next, let limit):
            return .requestQuery(compactQuery([
                "category": category,
                "next": next,
                "limit": limit
            ]))

        case .detail, .delete, .deleteComment:
            return .requestPlain
        }
    }

    var requiresAuth: Bool { true }
}

enum ChatAPI: APIEndpoint {
    case createRoom(body: any Encodable)
    case fetchRooms
    case sendMessage(roomID: String, body: any Encodable)
    case fetchMessages(roomID: String, next: String?)
    case uploadFiles(roomID: String, files: [UploadFile])

    var path: String {
        switch self {
        case .createRoom, .fetchRooms:
            return "v1/chats"
        case .sendMessage(let roomID, _), .fetchMessages(let roomID, _):
            return "v1/chats/\(roomID)"
        case .uploadFiles(let roomID, _):
            return "v1/chats/\(roomID)/files"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createRoom, .sendMessage, .uploadFiles:
            return .post
        case .fetchRooms, .fetchMessages:
            return .get
        }
    }

    var task: APITask {
        switch self {
        case .createRoom(let body), .sendMessage(_, let body):
            return .requestJSON(body)
        case .fetchRooms:
            return .requestPlain
        case .fetchMessages(_, let next):
            return .requestQuery(compactQuery([
                "next": next
            ]))
        case .uploadFiles(_, let files):
            return .uploadFiles(files)
        }
    }

    var requiresAuth: Bool { true }
}

enum BannerAPI: APIEndpoint {
    case main

    var path: String { "v1/banners/main" }
    var method: HTTPMethod { .get }
    var task: APITask { .requestPlain }
    var requiresAuth: Bool { true }
}

enum LogAPI: APIEndpoint {
    case fetch

    var path: String { "v1/log" }
    var method: HTTPMethod { .get }
    var task: APITask { .requestPlain }
    var requiresAuth: Bool { false }
}

enum OrderAPI: APIEndpoint {
    case create(body: any Encodable)
    case list

    var path: String { "v1/orders" }

    var method: HTTPMethod {
        switch self {
        case .create: return .post
        case .list: return .get
        }
    }

    var task: APITask {
        switch self {
        case .create(let body): return .requestJSON(body)
        case .list: return .requestPlain
        }
    }

    var requiresAuth: Bool { true }
}

enum PaymentAPI: APIEndpoint {
    case validate(body: any Encodable)
    case detail(orderCode: String)

    var path: String {
        switch self {
        case .validate: return "v1/payments/validation"
        case .detail(let code): return "v1/payments/\(code)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .validate: return .post
        case .detail: return .get
        }
    }

    var task: APITask {
        switch self {
        case .validate(let body): return .requestJSON(body)
        case .detail: return .requestPlain
        }
    }

    var requiresAuth: Bool { true }
}

enum NotificationAPI: APIEndpoint {
    case push(body: any Encodable)

    var path: String { "v1/notifications/push" }
    var method: HTTPMethod { .post }
    var task: APITask {
        switch self {
        case .push(let body):
            return .requestJSON(body)
        }
    }
    var requiresAuth: Bool { true }
}

enum VideoAPI: APIEndpoint {
    case list(next: String?, limit: Int?)
    case stream(videoID: String)
    case like(videoID: String, body: any Encodable)

    var path: String {
        switch self {
        case .list:
            return "v1/videos"
        case .stream(let id):
            return "v1/videos/\(id)/stream"
        case .like(let id, _):
            return "v1/videos/\(id)/like"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .stream:
            return .get
        case .like:
            return .post
        }
    }

    var task: APITask {
        switch self {
        case .list(let next, let limit):
            return .requestQuery(compactQuery([
                "next": next,
                "limit": limit
            ]))
        case .stream:
            return .requestPlain
        case .like(_, let body):
            return .requestJSON(body)
        }
    }

    var requiresAuth: Bool { true }
}

// MARK: - Helpers

private func compactQuery(_ parameters: [String: Any?]) -> Parameters {
    parameters.reduce(into: Parameters()) { partialResult, entry in
        if let value = entry.value {
            partialResult[entry.key] = value
        }
    }
}

/// 빈 응답을 표현할 때 사용
private struct EmptyResponse: Decodable {}

private struct AnyEncodable: Encodable {
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
