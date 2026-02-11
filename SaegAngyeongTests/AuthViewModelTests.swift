//
//  AuthViewModelTests.swift
//  SaegAngyeongTests
//
//  Created by andev on 2/11/26.
//

import XCTest
import Combine
@testable import SaegAngyeong

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []
    private static var retainedViewModels: [AnyObject] = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    private func retainForTestLifetime(_ object: AnyObject) {
        Self.retainedViewModels.append(object)
    }

    func testLoginViewModel_emailLoginSuccess_emitsSessionAndCallsRepository() {
        let repository = MockAuthRepository()
        let expectedSession = makeAuthSession(accessToken: "access-1", refreshToken: "refresh-1")
        repository.loginResult = .success(expectedSession)

        let emailLogin = PassthroughSubject<EmailLoginForm, Never>()
        let appleLogin = PassthroughSubject<String, Never>()
        let sut = LoginViewModel(
            authRepository: repository,
            deviceTokenProvider: { "device-token-1" }
        )
        retainForTestLifetime(sut)

        let output = sut.transform(
            input: .init(
                appleIDToken: appleLogin.eraseToAnyPublisher(),
                emailLogin: emailLogin.eraseToAnyPublisher()
            )
        )

        let successExpectation = expectation(description: "login success emitted")
        output.loginSuccess
            .sink { session in
                XCTAssertEqual(session.tokens.accessToken, expectedSession.tokens.accessToken)
                XCTAssertEqual(session.tokens.refreshToken, expectedSession.tokens.refreshToken)
                successExpectation.fulfill()
            }
            .store(in: &cancellables)

        emailLogin.send(.init(email: "user@test.com", password: "password!2"))

        wait(for: [successExpectation], timeout: 1.0)

        XCTAssertEqual(repository.loginCalledCount, 1)
        XCTAssertEqual(repository.lastLoginEmail, "user@test.com")
        XCTAssertEqual(repository.lastLoginPassword, "password!2")
        XCTAssertEqual(repository.lastLoginDeviceToken, "device-token-1")
    }

    func testLoginViewModel_invalidEmail_emitsValidationErrorAndDoesNotCallRepository() {
        let repository = MockAuthRepository()
        let emailLogin = PassthroughSubject<EmailLoginForm, Never>()
        let appleLogin = PassthroughSubject<String, Never>()
        let sut = LoginViewModel(
            authRepository: repository,
            deviceTokenProvider: { "device-token-1" }
        )
        retainForTestLifetime(sut)

        _ = sut.transform(
            input: .init(
                appleIDToken: appleLogin.eraseToAnyPublisher(),
                emailLogin: emailLogin.eraseToAnyPublisher()
            )
        )

        let errorExpectation = expectation(description: "validation error emitted")
        sut.error
            .sink { error in
                guard let domainError = error as? DomainError else {
                    XCTFail("Expected DomainError but got \(type(of: error))")
                    errorExpectation.fulfill()
                    return
                }
                guard case let .validation(message) = domainError else {
                    XCTFail("Expected validation error but got \(domainError)")
                    errorExpectation.fulfill()
                    return
                }
                XCTAssertEqual(message, "이메일 형식이 올바르지 않습니다.")
                errorExpectation.fulfill()
            }
            .store(in: &cancellables)

        emailLogin.send(.init(email: "invalid-email", password: "password!2"))

        wait(for: [errorExpectation], timeout: 1.0)
        XCTAssertEqual(repository.loginCalledCount, 0)
    }

    func testLoginViewModel_appleLoginFailure_emitsDomainError() {
        let repository = MockAuthRepository()
        repository.loginAppleResult = .failure(.network)
        let emailLogin = PassthroughSubject<EmailLoginForm, Never>()
        let appleLogin = PassthroughSubject<String, Never>()
        let sut = LoginViewModel(
            authRepository: repository,
            deviceTokenProvider: { "device-token-apple" }
        )
        retainForTestLifetime(sut)

        _ = sut.transform(
            input: .init(
                appleIDToken: appleLogin.eraseToAnyPublisher(),
                emailLogin: emailLogin.eraseToAnyPublisher()
            )
        )

        let errorExpectation = expectation(description: "network error emitted")
        sut.error
            .sink { error in
                guard let domainError = error as? DomainError else {
                    XCTFail("Expected DomainError but got \(type(of: error))")
                    errorExpectation.fulfill()
                    return
                }
                guard case .network = domainError else {
                    XCTFail("Expected network error but got \(domainError)")
                    errorExpectation.fulfill()
                    return
                }
                errorExpectation.fulfill()
            }
            .store(in: &cancellables)

        appleLogin.send("apple-id-token")

        wait(for: [errorExpectation], timeout: 1.0)
        XCTAssertEqual(repository.loginAppleCalledCount, 1)
        XCTAssertEqual(repository.lastAppleIDToken, "apple-id-token")
        XCTAssertEqual(repository.lastAppleDeviceToken, "device-token-apple")
    }

    func testJoinViewModel_submitSuccess_parsesHashTagsAndCallsRepository() {
        let repository = MockAuthRepository()
        let expectedSession = makeAuthSession(accessToken: "access-join", refreshToken: "refresh-join")
        repository.joinResult = .success(expectedSession)

        let submit = PassthroughSubject<JoinForm, Never>()
        let sut = JoinViewModel(
            authRepository: repository,
            deviceTokenProvider: { "join-device-token" }
        )
        retainForTestLifetime(sut)

        let output = sut.transform(input: .init(submit: submit.eraseToAnyPublisher()))

        let successExpectation = expectation(description: "join success emitted")
        output.joinSuccess
            .sink { session in
                XCTAssertEqual(session.tokens.accessToken, expectedSession.tokens.accessToken)
                XCTAssertEqual(session.tokens.refreshToken, expectedSession.tokens.refreshToken)
                successExpectation.fulfill()
            }
            .store(in: &cancellables)

        submit.send(
            .init(
                email: "join@test.com",
                password: "Password!1",
                nick: "newbie",
                name: "",
                introduction: "",
                phoneNum: "",
                hashTagsText: "#ios, swift combine, #tdd"
            )
        )

        wait(for: [successExpectation], timeout: 1.0)

        XCTAssertEqual(repository.joinCalledCount, 1)
        XCTAssertEqual(repository.lastJoinEmail, "join@test.com")
        XCTAssertEqual(repository.lastJoinPassword, "Password!1")
        XCTAssertEqual(repository.lastJoinNick, "newbie")
        XCTAssertNil(repository.lastJoinName)
        XCTAssertNil(repository.lastJoinIntroduction)
        XCTAssertNil(repository.lastJoinPhone)
        XCTAssertEqual(repository.lastJoinHashTags, ["ios", "swift", "combine", "tdd"])
        XCTAssertEqual(repository.lastJoinDeviceToken, "join-device-token")
    }

    func testJoinViewModel_invalidPassword_emitsValidationErrorAndDoesNotCallRepository() {
        let repository = MockAuthRepository()
        let submit = PassthroughSubject<JoinForm, Never>()
        let sut = JoinViewModel(
            authRepository: repository,
            deviceTokenProvider: { "join-device-token" }
        )
        retainForTestLifetime(sut)

        _ = sut.transform(input: .init(submit: submit.eraseToAnyPublisher()))

        let errorExpectation = expectation(description: "password validation error emitted")
        sut.error
            .sink { error in
                guard let domainError = error as? DomainError else {
                    XCTFail("Expected DomainError but got \(type(of: error))")
                    errorExpectation.fulfill()
                    return
                }
                guard case let .validation(message) = domainError else {
                    XCTFail("Expected validation error but got \(domainError)")
                    errorExpectation.fulfill()
                    return
                }
                XCTAssertEqual(
                    message,
                    "비밀번호는 8자 이상이며 영문/숫자/특수문자를 각각 1개 이상 포함해야 합니다."
                )
                errorExpectation.fulfill()
            }
            .store(in: &cancellables)

        submit.send(
            .init(
                email: "join@test.com",
                password: "12345678",
                nick: "nick",
                name: "",
                introduction: "",
                phoneNum: "",
                hashTagsText: ""
            )
        )

        wait(for: [errorExpectation], timeout: 1.0)
        XCTAssertEqual(repository.joinCalledCount, 0)
    }

    private func makeAuthSession(accessToken: String, refreshToken: String) -> AuthSession {
        let user = UserProfile(
            id: "user-id",
            email: "user@test.com",
            nick: "tester",
            name: "Tester",
            introduction: nil,
            description: nil,
            phoneNumber: nil,
            profileImageURL: nil,
            hashTags: []
        )
        let tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
        return AuthSession(user: user, tokens: tokens)
    }
}

private final class MockAuthRepository: AuthRepository {
    var loginResult: Result<AuthSession, DomainError> = .failure(.unknown(message: nil))
    var loginAppleResult: Result<AuthSession, DomainError> = .failure(.unknown(message: nil))
    var joinResult: Result<AuthSession, DomainError> = .failure(.unknown(message: nil))

    var loginCalledCount = 0
    var loginAppleCalledCount = 0
    var joinCalledCount = 0

    var lastLoginEmail: String?
    var lastLoginPassword: String?
    var lastLoginDeviceToken: String?

    var lastAppleIDToken: String?
    var lastAppleDeviceToken: String?

    var lastJoinEmail: String?
    var lastJoinPassword: String?
    var lastJoinNick: String?
    var lastJoinName: String?
    var lastJoinIntroduction: String?
    var lastJoinPhone: String?
    var lastJoinHashTags: [String]?
    var lastJoinDeviceToken: String?

    func login(email: String, password: String, deviceToken: String?) -> AnyPublisher<AuthSession, DomainError> {
        loginCalledCount += 1
        lastLoginEmail = email
        lastLoginPassword = password
        lastLoginDeviceToken = deviceToken
        return publisher(from: loginResult)
    }

    func loginKakao(oauthToken: String, deviceToken: String?) -> AnyPublisher<AuthSession, DomainError> {
        publisher(from: .failure(.unknown(message: "not used")))
    }

    func loginApple(idToken: String, deviceToken: String?) -> AnyPublisher<AuthSession, DomainError> {
        loginAppleCalledCount += 1
        lastAppleIDToken = idToken
        lastAppleDeviceToken = deviceToken
        return publisher(from: loginAppleResult)
    }

    func join(
        email: String,
        password: String,
        nick: String,
        name: String?,
        introduction: String?,
        phone: String?,
        hashTags: [String],
        deviceToken: String?
    ) -> AnyPublisher<AuthSession, DomainError> {
        joinCalledCount += 1
        lastJoinEmail = email
        lastJoinPassword = password
        lastJoinNick = nick
        lastJoinName = name
        lastJoinIntroduction = introduction
        lastJoinPhone = phone
        lastJoinHashTags = hashTags
        lastJoinDeviceToken = deviceToken
        return publisher(from: joinResult)
    }

    func refresh(refreshToken: String) -> AnyPublisher<AuthTokens, DomainError> {
        publisher(from: .failure(.unknown(message: "not used")))
    }

    func logout() -> AnyPublisher<Void, DomainError> {
        publisher(from: .success(()))
    }

    func updateDeviceToken(_ token: String) -> AnyPublisher<Void, DomainError> {
        publisher(from: .success(()))
    }

    private func publisher<T>(from result: Result<T, DomainError>) -> AnyPublisher<T, DomainError> {
        switch result {
        case let .success(value):
            return Just(value)
                .setFailureType(to: DomainError.self)
                .eraseToAnyPublisher()
        case let .failure(error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
