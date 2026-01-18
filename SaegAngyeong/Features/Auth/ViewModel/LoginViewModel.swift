//
//  LoginViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Combine

struct EmailLoginForm {
    let email: String
    let password: String
}

final class LoginViewModel: BaseViewModel, ViewModelType {

    struct Input {
        /// Apple ID Token 문자열
        let appleIDToken: AnyPublisher<String, Never>
        let emailLogin: AnyPublisher<EmailLoginForm, Never>
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
                AppLogger.debug("[Login] Apple ID Token: \(idToken)")
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
                AppLogger.debug("[Login] Apple login success: \(session)")
                successSubject.send(session)
            }
            .store(in: &cancellables)

        input.emailLogin
            .flatMap { [weak self] form -> AnyPublisher<AuthSession, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                if let error = self.validate(form: form) {
                    self.error.send(error)
                    return Empty().eraseToAnyPublisher()
                }
                self.isLoading.send(true)
                return self.authRepository.login(
                    email: form.email,
                    password: form.password,
                    deviceToken: self.deviceTokenProvider()
                )
            }
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { session in
                successSubject.send(session)
            }
            .store(in: &cancellables)

        return Output(
            loginSuccess: successSubject.eraseToAnyPublisher()
        )
    }

    private func validate(form: EmailLoginForm) -> DomainError? {
        let email = form.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = form.password

        guard !email.isEmpty else { return .validation(message: "이메일을 입력해주세요.") }
        guard isValidEmail(email) else { return .validation(message: "이메일 형식이 올바르지 않습니다.") }
        guard !password.isEmpty else { return .validation(message: "비밀번호를 입력해주세요.") }
        return nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }
}
