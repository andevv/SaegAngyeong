//
//  TokenRefreshInterceptor.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Alamofire

/// 401 응답 시 리프레시 토큰으로 재발급 후 재시도하는 인터셉터
final class TokenRefreshInterceptor: RequestInterceptor {

    private let tokenStore: TokenStore
    private let apiKey: String
    private let session: Session
    private let lock = NSLock()

    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []

    private let onForceLogout: () -> Void

    init(tokenStore: TokenStore, apiKey: String, onForceLogout: @escaping () -> Void) {
        self.tokenStore = tokenStore
        self.apiKey = apiKey
        self.onForceLogout = onForceLogout
        // 리프레시 요청에는 인터셉터가 걸리지 않은 세션 사용
        self.session = Session()
    }

    // MARK: - Adapt

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest

        // SeSACKey 항상 갱신
        request.setValue(apiKey, forHTTPHeaderField: "SeSACKey")

        // 최신 accessToken 붙이기
        if let accessToken = tokenStore.accessToken, !accessToken.isEmpty {
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }

        completion(.success(request))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard
            let response = request.response,
            response.statusCode == 401 || response.statusCode == 419,
            request.request?.url?.path.contains("v1/auth/refresh") == false
        else {
            if let response = request.response, response.statusCode == 418 {
                // 리프레시 토큰 만료
                onForceLogout()
                completion(.doNotRetry)
                return
            }
            completion(.doNotRetry)
            return
        }

        guard let refreshToken = tokenStore.refreshToken else {
            completion(.doNotRetry)
            return
        }

        lock.lock()
        requestsToRetry.append(completion)

        if !isRefreshing {
            isRefreshing = true
            lock.unlock()
            refreshTokens(refreshToken: refreshToken)
        } else {
            lock.unlock()
        }
    }

    private func refreshTokens(refreshToken: String) {
        let router = APIRouter(
            endpoint: AuthAPI.refresh(refreshToken: refreshToken),
            accessTokenProvider: { [weak tokenStore] in tokenStore?.accessToken },
            sesacKey: apiKey
        )

        session.request(router)
            .validate()
            .responseData { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let data):
                    do {
                        let dto = try JSONDecoder().decode(RefreshTokenResponseDTO.self, from: data)
                        self.tokenStore.accessToken = dto.accessToken
                        self.tokenStore.refreshToken = dto.refreshToken
                        self.finishRetrying(with: .retry)
                    } catch {
                        self.finishRetrying(with: .doNotRetryWithError(error))
                    }
                case .failure(let error):
                    if response.response?.statusCode == 418 || response.response?.statusCode == 401 {
                        self.onForceLogout()
                    }
                    self.finishRetrying(with: .doNotRetryWithError(error))
                }
            }
    }

    private func finishRetrying(with result: RetryResult) {
        lock.lock()
        let completions = requestsToRetry
        requestsToRetry.removeAll()
        isRefreshing = false
        lock.unlock()

        completions.forEach { $0(result) }
    }
}
