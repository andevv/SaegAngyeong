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
        label.text = "색안경"
        label.font = .mulgyeol(.bold, size: 30)
        label.textAlignment = .center
        label.textColor = .gray60
        return label
    }()

    private let logoImageView = UIImageView(image: UIImage(named: "AppLogo"))
    private let emailLabel = UILabel()
    private let emailField = UITextField()

    private let passwordLabel = UILabel()
    private let passwordField = UITextField()

    private let emailLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("이메일로 로그인", for: .normal)
        button.titleLabel?.font = .pretendard(.medium, size: 14)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .deepTurquoise
        button.layer.cornerRadius = 12
        return button
    }()

    private let appleButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .continue, style: .white)
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

    private let loginStack = UIStackView()
    private let buttonStack = UIStackView()

    // MARK: - Properties
    private let appleIDTokenSubject = PassthroughSubject<String, Never>()
    private let emailLoginSubject = PassthroughSubject<EmailLoginForm, Never>()
    var onLoginSuccess: ((AuthSession) -> Void)?
    var onJoinRequested: (() -> Void)?

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        appleButton.addTarget(self, action: #selector(appleLoginTapped), for: .touchUpInside)
        emailLoginButton.addTarget(self, action: #selector(emailLoginTapped), for: .touchUpInside)
        emailField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    // MARK: - BaseViewController Overrides
    override func configureUI() {
        view.backgroundColor = .black

        logoImageView.contentMode = .scaleAspectFit

        emailLabel.text = "이메일"
        emailLabel.textColor = .gray60
        emailLabel.font = .pretendard(.medium, size: 12)
        configureField(emailField, placeholder: "user@example.com")
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no

        passwordLabel.text = "비밀번호"
        passwordLabel.textColor = .gray60
        passwordLabel.font = .pretendard(.medium, size: 12)
        configureField(passwordField, placeholder: "비밀번호를 입력하세요.")
        passwordField.isSecureTextEntry = true
        updateLoginButtonState()

        loginStack.axis = .vertical
        loginStack.spacing = 8
        loginStack.addArrangedSubview(emailLabel)
        loginStack.addArrangedSubview(emailField)
        loginStack.setCustomSpacing(16, after: emailField)
        loginStack.addArrangedSubview(passwordLabel)
        loginStack.addArrangedSubview(passwordField)
        loginStack.setCustomSpacing(20, after: passwordField)
        loginStack.addArrangedSubview(emailLoginButton)

        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.addArrangedSubview(joinButton)
        buttonStack.addArrangedSubview(appleButton)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        [
            logoImageView,
            titleLabel,
            loginStack,
            buttonStack
        ].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(24)
        }

        logoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(32)
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
        }

        loginStack.snp.makeConstraints { make in
            make.centerY.equalTo(view.safeAreaLayoutGuide).offset(-12)
            make.horizontalEdges.equalToSuperview().inset(24)
        }

        buttonStack.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
        }
        
        joinButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        appleButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        emailField.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        passwordField.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        emailLoginButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }

    override func bindViewModel() {
        let input = LoginViewModel.Input(
            appleIDToken: appleIDTokenSubject.eraseToAnyPublisher(),
            emailLogin: emailLoginSubject.eraseToAnyPublisher()
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
    private func emailLoginTapped() {
        let form = EmailLoginForm(
            email: emailField.text ?? "",
            password: passwordField.text ?? ""
        )
        emailLoginSubject.send(form)
    }

    @objc
    private func joinTapped() {
        onJoinRequested?()
    }

    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc
    private func textFieldDidChange() {
        updateLoginButtonState()
    }

    private func configureField(_ field: UITextField, placeholder: String) {
        field.textColor = .gray30
        field.font = .pretendard(.regular, size: 12)
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.gray75]
        )
        field.backgroundColor = .blackTurquoise
        field.layer.cornerRadius = 10
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.gray90.withAlphaComponent(0.3).cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        field.leftViewMode = .always
    }

    private func updateLoginButtonState() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        let isValid = isValidEmail(email) && !password.isEmpty
        emailLoginButton.isEnabled = isValid
        emailLoginButton.backgroundColor = isValid ? .brightTurquoise : .blackTurquoise
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
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
