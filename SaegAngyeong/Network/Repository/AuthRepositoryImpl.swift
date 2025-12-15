//
//  AuthRepositoryImpl.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Combine

/// 네트워크 기반 AuthRepository 구현체
final class AuthRepositoryImpl: AuthRepository {

    private let network: NetworkProviding
    private let tokenStore: TokenStore

    init(network: NetworkProviding, tokenStore: TokenStore) {
        self.network = network
        self.tokenStore = tokenStore
    }

    // MARK: - Email Login / Kakao / Apple / Join

    func login(email: String, password: String, deviceToken: String?) -> AnyPublisher<AuthSession, DomainError> {
        let body = LoginRequest(email: email, password: password, deviceToken: deviceToken)
        return network.request(LoginResponseDTO.self, endpoint: UserAPI.login(body: body))
            .mapError { _ in DomainError.network }
            .map(handleAuthSuccess)
            .eraseToAnyPublisher()
    }

    func loginKakao(oauthToken: String, deviceToken: String?) -> AnyPublisher<AuthSession, DomainError> {
        let body = KakaoLoginRequest(oauthToken: oauthToken, deviceToken: deviceToken)
        return network.request(LoginResponseDTO.self, endpoint: UserAPI.loginKakao(body: body))
            .mapError { _ in DomainError.network }
            .map(handleAuthSuccess)
            .eraseToAnyPublisher()
    }

    func loginApple(idToken: String, deviceToken: String?) -> AnyPublisher<AuthSession, DomainError> {
        let body = AppleLoginRequest(idToken: idToken, deviceToken: deviceToken)
        return network.request(LoginResponseDTO.self, endpoint: UserAPI.loginApple(body: body))
            .mapError { _ in DomainError.network }
            .map(handleAuthSuccess)
            .eraseToAnyPublisher()
    }

    func join(email: String, password: String, nick: String, name: String?, introduction: String?, phone: String?, hashTags: [String], deviceToken: String?) -> AnyPublisher<AuthSession, DomainError> {
        let body = JoinRequest(
            email: email,
            password: password,
            nick: nick,
            name: name,
            introduction: introduction,
            phoneNum: phone,
            hashTags: hashTags,
            deviceToken: deviceToken
        )

        return network.request(LoginResponseDTO.self, endpoint: UserAPI.join(body: body))
            .mapError { _ in DomainError.network }
            .map(handleAuthSuccess)
            .eraseToAnyPublisher()
    }

    // MARK: - Token

    func refresh(refreshToken: String) -> AnyPublisher<AuthTokens, DomainError> {
        network.request(RefreshTokenResponseDTO.self, endpoint: AuthAPI.refresh(refreshToken: refreshToken))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                self?.tokenStore.accessToken = dto.accessToken
                self?.tokenStore.refreshToken = dto.refreshToken
                return AuthTokens(accessToken: dto.accessToken, refreshToken: dto.refreshToken)
            }
            .eraseToAnyPublisher()
    }

    func logout() -> AnyPublisher<Void, DomainError> {
        network.requestVoid(UserAPI.logout)
            .mapError { _ in DomainError.network }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.tokenStore.clear()
            })
            .eraseToAnyPublisher()
    }

    func updateDeviceToken(_ token: String) -> AnyPublisher<Void, DomainError> {
        tokenStore.deviceToken = token
        let body = DeviceTokenRequest(deviceToken: token)
        return network.requestVoid(UserAPI.updateDeviceToken(body: body))
            .mapError { _ in DomainError.network }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func handleAuthSuccess(_ dto: LoginResponseDTO) -> AuthSession {
        let userProfile = UserProfile(
            id: dto.userID,
            email: dto.email,
            nick: dto.nick,
            name: dto.name,
            introduction: dto.introduction,
            phoneNumber: dto.phoneNum,
            profileImageURL: dto.profileImage.flatMap { URL(string: $0) },
            hashTags: dto.hashTags ?? []
        )

        let tokens = AuthTokens(accessToken: dto.accessToken, refreshToken: dto.refreshToken)
        tokenStore.accessToken = dto.accessToken
        tokenStore.refreshToken = dto.refreshToken

        return AuthSession(user: userProfile, tokens: tokens)
    }
}
