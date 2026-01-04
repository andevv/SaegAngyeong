//
//  JoinViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/4/26.
//

import UIKit
import SnapKit
import Combine

final class JoinViewController: BaseViewController<JoinViewModel> {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private lazy var keyboardObserver = KeyboardInsetObserver(scrollView: scrollView, containerView: view)

    private let emailLabel = UILabel()
    private let emailField = UITextField()

    private let passwordLabel = UILabel()
    private let passwordField = UITextField()

    private let nickLabel = UILabel()
    private let nickField = UITextField()

    private let nameLabel = UILabel()
    private let nameField = UITextField()

    private let introLabel = UILabel()
    private let introContainer = UIView()
    private let introTextView = UITextView()
    private let introPlaceholderLabel = UILabel()

    private let phoneLabel = UILabel()
    private let phoneField = UITextField()

    private let hashTagLabel = UILabel()
    private let hashTagField = UITextField()

    private let submitButton = UIButton(type: .system)
    private let submitSubject = PassthroughSubject<JoinForm, Never>()

    var onJoinSuccess: ((AuthSession) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardObserver.start()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.gray60
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray60
        navigationController?.navigationBar.barStyle = .black
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardObserver.stop()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func configureUI() {
        let titleLabel = UILabel()
        titleLabel.text = "회원가입"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)

        emailLabel.text = "이메일"
        passwordLabel.text = "비밀번호"
        nickLabel.text = "닉네임"
        nameLabel.text = "이름"
        introLabel.text = "소개"
        phoneLabel.text = "연락처"
        hashTagLabel.text = "해시태그"

        [emailLabel, passwordLabel, nickLabel, nameLabel, introLabel, phoneLabel, hashTagLabel].forEach { label in
            label.textColor = .gray60
            label.font = .pretendard(.medium, size: 12)
        }

        configureField(emailField, placeholder: "user@example.com")
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no

        configureField(passwordField, placeholder: "영문/숫자/특수문자 포함 8자 이상")
        passwordField.isSecureTextEntry = true

        configureField(nickField, placeholder: "닉네임을 입력하세요.")
        configureField(nameField, placeholder: "이름을 입력하세요.")

        configureField(phoneField, placeholder: "010-1234-1234")
        phoneField.keyboardType = .phonePad

        configureField(hashTagField, placeholder: "#빈티지, #감성")

        introContainer.backgroundColor = .blackTurquoise
        introContainer.layer.cornerRadius = 10
        introContainer.layer.borderWidth = 1
        introContainer.layer.borderColor = UIColor.gray90.withAlphaComponent(0.3).cgColor

        introTextView.backgroundColor = .clear
        introTextView.textColor = .gray30
        introTextView.font = .pretendard(.regular, size: 12)
        introTextView.delegate = self
        introTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        introPlaceholderLabel.text = "소개를 입력하세요."
        introPlaceholderLabel.textColor = .gray60
        introPlaceholderLabel.font = .pretendard(.regular, size: 12)

        submitButton.setTitle("회원가입", for: .normal)
        submitButton.titleLabel?.font = .pretendard(.medium, size: 14)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.backgroundColor = .deepTurquoise
        submitButton.layer.cornerRadius = 12
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        [
            emailLabel,
            emailField,
            passwordLabel,
            passwordField,
            nickLabel,
            nickField,
            nameLabel,
            nameField,
            introLabel,
            introContainer,
            phoneLabel,
            phoneField,
            hashTagLabel,
            hashTagField,
            submitButton
        ].forEach { contentView.addSubview($0) }

        introContainer.addSubview(introTextView)
        introContainer.addSubview(introPlaceholderLabel)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        emailLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        emailField.snp.makeConstraints { make in
            make.top.equalTo(emailLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(42)
        }

        passwordLabel.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        passwordField.snp.makeConstraints { make in
            make.top.equalTo(passwordLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(42)
        }

        nickLabel.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        nickField.snp.makeConstraints { make in
            make.top.equalTo(nickLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(42)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(nickField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        nameField.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(42)
        }

        introLabel.snp.makeConstraints { make in
            make.top.equalTo(nameField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        introContainer.snp.makeConstraints { make in
            make.top.equalTo(introLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }

        introTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        introPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(12)
        }

        phoneLabel.snp.makeConstraints { make in
            make.top.equalTo(introContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        phoneField.snp.makeConstraints { make in
            make.top.equalTo(phoneLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(42)
        }

        hashTagLabel.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        hashTagField.snp.makeConstraints { make in
            make.top.equalTo(hashTagLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(42)
        }

        submitButton.snp.makeConstraints { make in
            make.top.equalTo(hashTagField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    override func bindViewModel() {
        let input = JoinViewModel.Input(submit: submitSubject.eraseToAnyPublisher())
        let output = viewModel.transform(input: input)

        output.joinSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.onJoinSuccess?(session)
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    @objc
    private func submitTapped() {
        let form = JoinForm(
            email: emailField.text ?? "",
            password: passwordField.text ?? "",
            nick: nickField.text ?? "",
            name: nameField.text ?? "",
            introduction: introTextView.text ?? "",
            phoneNum: phoneField.text ?? "",
            hashTagsText: hashTagField.text ?? ""
        )
        submitSubject.send(form)
    }

    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func configureField(_ field: UITextField, placeholder: String) {
        field.textColor = .gray30
        field.font = .pretendard(.regular, size: 12)
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.gray60]
        )
        field.backgroundColor = .blackTurquoise
        field.layer.cornerRadius = 10
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.gray90.withAlphaComponent(0.3).cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        field.leftViewMode = .always
    }

    private func presentError(_ error: Error) {
        let message: String
        if let domainError = error as? DomainError {
            switch domainError {
            case .validation(let text):
                message = text
            case .unknown(let text):
                message = text ?? "요청 처리 중 오류가 발생했습니다."
            default:
                message = "요청 처리 중 오류가 발생했습니다."
            }
        } else {
            message = error.localizedDescription
        }
        let alert = UIAlertController(title: "회원가입 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension JoinViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        introPlaceholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
