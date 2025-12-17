//
//  AppDependency.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Alamofire

/// 앱 전역에서 주입할 의존성을 보관/생성하는 컨테이너
struct AppDependency {
    let tokenStore: TokenStore
    let networkProvider: NetworkProviding
    let authRepository: AuthRepository
    let filterRepository: FilterRepository
    let bannerRepository: BannerRepository
    let userRepository: UserRepository

    static func make() -> AppDependency {
        let tokenStore = TokenStore()
        let etagStore = ETagStore()
        KingfisherETagConfigurator.configure(store: etagStore)
        let interceptor = TokenRefreshInterceptor(
            tokenStore: tokenStore,
            apiKey: AppConfig.apiKey,
            onForceLogout: {
                NotificationCenter.default.post(name: .tokenInvalidated, object: nil)
            }
        )
        let logger = NetworkLogger()
        let session = Session(interceptor: interceptor, eventMonitors: [logger])
        let provider = NetworkProvider(
            session: session,
            accessTokenProvider: { tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let authRepository = AuthRepositoryImpl(
            network: provider,
            tokenStore: tokenStore
        )
        let filterRepository = FilterRepositoryImpl(network: provider)
        let bannerRepository = BannerRepositoryImpl(network: provider)
        let userRepository = UserRepositoryImpl(network: provider)
        return AppDependency(
            tokenStore: tokenStore,
            networkProvider: provider,
            authRepository: authRepository,
            filterRepository: filterRepository,
            bannerRepository: bannerRepository,
            userRepository: userRepository
        )
    }
}
