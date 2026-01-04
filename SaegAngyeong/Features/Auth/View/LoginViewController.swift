//
//  LoginViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import UIKit
import AuthenticationServices
import Combine
import SnapKit

final class LoginViewController: BaseViewController<LoginViewModel> {

    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "로그인"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Apple로 간편 로그인하세요."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let appleButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("이메일로 회원가입", for: .normal)
        button.titleLabel?.font = .pretendard(.medium, size: 13)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .deepTurquoise
        button.layer.cornerRadius = 12
        return button
    }()

    private let buttonStack = UIStackView()

    // MARK: - Properties
    private let appleIDTokenSubject = PassthroughSubject<String, Never>()
    var onLoginSuccess: ((AuthSession) -> Void)?
    var onJoinRequested: (() -> Void)?

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        appleButton.addTarget(self, action: #selector(appleLoginTapped), for: .touchUpInside)
    }

    // MARK: - BaseViewController Overrides
    override func configureUI() {
        view.backgroundColor = .systemBackground
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.addArrangedSubview(joinButton)
        buttonStack.addArrangedSubview(appleButton)

        [titleLabel, descriptionLabel, buttonStack].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(48)
            make.horizontalEdges.equalToSuperview().inset(24)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(24)
        }

        buttonStack.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(descriptionLabel.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
        }
        
        joinButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        appleButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
    }

    override func bindViewModel() {
        let input = LoginViewModel.Input(
            appleIDToken: appleIDTokenSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.loginSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.onLoginSuccess?(session)
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    @objc
    private func appleLoginTapped() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    @objc
    private func joinTapped() {
        onJoinRequested?()
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "로그인 실패", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let token = String(data: tokenData, encoding: .utf8)
        else {
            presentError(DomainError.validation(message: "Apple ID Token을 가져오지 못했습니다."))
            return
        }

        appleIDTokenSubject.send(token)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        presentError(error)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }
}
