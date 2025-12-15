//
//  LoginViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Combine

final class LoginViewModel: BaseViewModel, ViewModelType {

    struct Input {
        /// Apple ID Token 문자열
        let appleIDToken: AnyPublisher<String, Never>
    }

    struct Output {
        /// 로그인 성공 시 전달되는 세션
        let loginSuccess: AnyPublisher<AuthSession, Never>
    }

    private let authRepository: AuthRepository
    private let deviceTokenProvider: () -> String?

    init(
        authRepository: AuthRepository,
        deviceTokenProvider: @escaping () -> String?
    ) {
        self.authRepository = authRepository
        self.deviceTokenProvider = deviceTokenProvider
        super.init()
    }

    func transform(input: Input) -> Output {
        let successSubject = PassthroughSubject<AuthSession, Never>()

        input.appleIDToken
            .flatMap { [weak self] idToken -> AnyPublisher<AuthSession, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                print("[Login] Apple ID Token:", idToken)
                return self.authRepository.loginApple(
                    idToken: idToken,
                    deviceToken: self.deviceTokenProvider()
                )
            }
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { session in
                print("[Login] Apple login success:", session)
                successSubject.send(session)
            }
            .store(in: &cancellables)

        return Output(
            loginSuccess: successSubject.eraseToAnyPublisher()
        )
    }
}
