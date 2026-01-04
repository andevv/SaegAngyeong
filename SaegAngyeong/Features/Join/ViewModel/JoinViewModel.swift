//
//  JoinViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 1/4/26.
//

import Foundation
import Combine

struct JoinForm {
    let email: String
    let password: String
    let nick: String
    let name: String
    let introduction: String
    let phoneNum: String
    let hashTagsText: String
}

final class JoinViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let submit: AnyPublisher<JoinForm, Never>
    }

    struct Output {
        let joinSuccess: AnyPublisher<AuthSession, Never>
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

        input.submit
            .flatMap { [weak self] form -> AnyPublisher<AuthSession, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                if let error = self.validate(form: form) {
                    self.error.send(error)
                    return Empty().eraseToAnyPublisher()
                }
                self.isLoading.send(true)
                let hashTags = self.parseHashTags(from: form.hashTagsText)
                return self.authRepository.join(
                    email: form.email,
                    password: form.password,
                    nick: form.nick,
                    name: form.name.isEmpty ? nil : form.name,
                    introduction: form.introduction.isEmpty ? nil : form.introduction,
                    phone: form.phoneNum.isEmpty ? nil : form.phoneNum,
                    hashTags: hashTags,
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

        return Output(joinSuccess: successSubject.eraseToAnyPublisher())
    }

    private func validate(form: JoinForm) -> DomainError? {
        let email = form.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = form.password
        let nick = form.nick.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty else { return .validation(message: "이메일을 입력해주세요.") }
        guard isValidEmail(email) else { return .validation(message: "이메일 형식이 올바르지 않습니다.") }

        guard !password.isEmpty else { return .validation(message: "비밀번호를 입력해주세요.") }
        guard isValidPassword(password) else {
            return .validation(message: "비밀번호는 8자 이상이며 영문/숫자/특수문자를 각각 1개 이상 포함해야 합니다.")
        }

        guard !nick.isEmpty else { return .validation(message: "닉네임을 입력해주세요.") }
        guard isValidNick(nick) else {
            return .validation(message: "닉네임에 사용할 수 없는 문자가 포함되어 있습니다.")
        }

        return nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        let pattern = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
    }

    private func isValidNick(_ nick: String) -> Bool {
        let invalidCharacters = CharacterSet(charactersIn: "-.,?*@+^${}()|[]\\")
        return nick.rangeOfCharacter(from: invalidCharacters) == nil
    }

    private func parseHashTags(from text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ", ")
        return text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.hasPrefix("#") ? String($0.dropFirst()) : $0 }
    }
}
