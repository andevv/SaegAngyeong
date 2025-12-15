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

    static func make() -> AppDependency {
        let tokenStore = TokenStore()
        let provider = NetworkProvider(
            session: .default,
            accessTokenProvider: { tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let authRepository = AuthRepositoryImpl(
            network: provider,
            tokenStore: tokenStore
        )
        return AppDependency(
            tokenStore: tokenStore,
            networkProvider: provider,
            authRepository: authRepository
        )
    }
}
