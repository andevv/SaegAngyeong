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
    /// 기존에는 `.store(in: &cancellables)`로 구독을 Set에 보관했는데,
    /// Host 기반 테스트 환경에서 ViewModel deinit 타이밍과 결합될 때
    /// 런타임 메모리 크래시(pointer being freed...)가 재현됐다.
    /// 단일 submit 체인만 유지하면 충분하므로 구독을 명시적으로 1개만 보관해
    /// 해제 경로를 단순화했다.
    private var submitCancellable: AnyCancellable?

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

        /// 검증 실패를 flatMap 내부에서 Empty로 처리하면 completion/해제 경로가 복잡해진다.
        /// 먼저 compactMap에서 invalid form을 걸러내고 error만 발행해,
        /// 네트워크 흐름에는 "유효한 입력"만 들어가도록 분리했다.
        submitCancellable = input.submit
            .compactMap { [weak self] form -> JoinForm? in
                guard let self else { return nil }
                if let error = self.validate(form: form) {
                    self.error.send(error)
                    return nil
                }
                return form
            }
            .flatMap { [weak self] form -> AnyPublisher<AuthSession, DomainError> in
                /// self가 이미 해제된 경우에는 side effect 없이 종료한다.
                guard let self else { return Empty().eraseToAnyPublisher() }
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
                /// 성공/실패 어떤 경로든 로딩 상태를 false로 되돌린다.
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { session in
                successSubject.send(session)
            }

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
