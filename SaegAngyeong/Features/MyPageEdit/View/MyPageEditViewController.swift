//
//  MyPageEditViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/30/25.
//

import UIKit
import SnapKit
import Combine
import Kingfisher

final class MyPageEditViewController: BaseViewController<MyPageEditViewModel> {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let refreshControl = UIRefreshControl()
    private lazy var keyboardObserver = KeyboardInsetObserver(scrollView: scrollView, containerView: view)

    private let profileImageView = UIImageView()
    private let changeImageButton = UIButton(type: .system)

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

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let saveTappedSubject = PassthroughSubject<MyPageEditDraft, Never>()
    private var profileImageURL: URL?
    private var shouldRefreshProfile = false
    private var shouldForceRefreshImage = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        viewDidLoadSubject.send(())
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
        if shouldRefreshProfile {
            refreshSubject.send(())
            shouldRefreshProfile = false
        }
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
        titleLabel.text = "프로필 수정"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("저장", for: .normal)
        saveButton.titleLabel?.font = .pretendard(.medium, size: 13)
        saveButton.setTitleColor(.brightTurquoise, for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        refreshControl.tintColor = .gray60
        refreshControl.addTarget(self, action: #selector(refreshTriggered), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 40
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.gray90.withAlphaComponent(0.3).cgColor
        profileImageView.backgroundColor = .blackTurquoise
        profileImageView.image = UIImage(named: "Profile_Empty")

        changeImageButton.setTitle("프로필 이미지 변경", for: .normal)
        changeImageButton.titleLabel?.font = .pretendard(.medium, size: 12)
        changeImageButton.setTitleColor(.gray60, for: .normal)
        changeImageButton.layer.borderWidth = 1
        changeImageButton.layer.borderColor = UIColor.gray90.withAlphaComponent(0.4).cgColor
        changeImageButton.layer.cornerRadius = 10
        changeImageButton.addTarget(self, action: #selector(changeImageTapped), for: .touchUpInside)

        nickLabel.text = "닉네임"
        nameLabel.text = "이름"
        introLabel.text = "소개"
        phoneLabel.text = "연락처"
        hashTagLabel.text = "해시태그"

        [nickLabel, nameLabel, introLabel, phoneLabel, hashTagLabel].forEach { label in
            label.textColor = .gray60
            label.font = .pretendard(.medium, size: 12)
        }

        configureField(nickField, placeholder: "닉네임을 입력하세요.")
        configureField(nameField, placeholder: "이름을 입력하세요.")
        configureField(phoneField, placeholder: "010-1234-1234")
        phoneField.keyboardType = .phonePad

        configureField(hashTagField, placeholder: "#맑음, #감성")

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

        [
            profileImageView,
            changeImageButton,
            nickLabel,
            nickField,
            nameLabel,
            nameField,
            introLabel,
            introContainer,
            phoneLabel,
            phoneField,
            hashTagLabel,
            hashTagField
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

        profileImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().inset(20)
            make.width.height.equalTo(80)
        }

        changeImageButton.snp.makeConstraints { make in
            make.centerY.equalTo(profileImageView)
            make.leading.equalTo(profileImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(32)
        }

        nickLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(24)
            make.leading.equalToSuperview().inset(20)
        }

        nickField.snp.makeConstraints { make in
            make.top.equalTo(nickLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(nickField.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        nameField.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        introLabel.snp.makeConstraints { make in
            make.top.equalTo(nameField.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        introContainer.snp.makeConstraints { make in
            make.top.equalTo(introLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(90)
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
            make.leading.equalToSuperview().inset(20)
        }

        phoneField.snp.makeConstraints { make in
            make.top.equalTo(phoneLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        hashTagLabel.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        hashTagField.snp.makeConstraints { make in
            make.top.equalTo(hashTagLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    override func bindViewModel() {
        let input = MyPageEditViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            refresh: refreshSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.profile
            .sink { [weak self] profile in
                self?.applyProfile(profile)
                self?.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)

        output.saveCompleted
            .sink { [weak self] _ in
                self?.presentSaveSuccess()
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.refreshControl.endRefreshing()
                self?.presentError(error)
            }
            .store(in: &cancellables)
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

    private func applyProfile(_ profile: UserProfile?) {
        guard let profile else { return }
        nickField.text = profile.nick
        nameField.text = profile.name ?? ""
        introTextView.text = profile.introduction ?? ""
        introPlaceholderLabel.isHidden = !(introTextView.text?.isEmpty ?? true)
        phoneField.text = profile.phoneNumber ?? ""
        hashTagField.text = profile.hashTags.joined(separator: ", ")
        let fallback = profileImageView.image ?? UIImage(named: "Profile_Empty")
        let retryStrategy = DelayRetryStrategy(maxRetryCount: 3, retryInterval: .seconds(0.5))
        if let url = profile.profileImageURL {
            profileImageURL = url
            let displayURL = shouldForceRefreshImage ? cacheBustedURL(from: url) : url
            let modifier = KingfisherHelper.modifier(headers: viewModel.imageHeaders)
            var options: KingfisherOptionsInfo = [
                .requestModifier(modifier),
                .cacheOriginalImage,
                .keepCurrentImageWhileLoading,
                .retryStrategy(retryStrategy)
            ]
            if shouldForceRefreshImage {
                options.append(.forceRefresh)
                shouldForceRefreshImage = false
            }
            profileImageView.kf.setImage(
                with: displayURL,
                placeholder: fallback,
                options: options
            )
        } else {
            profileImageView.image = fallback
        }
    }

    private func presentSaveSuccess() {
        let alert = UIAlertController(title: "완료", message: "프로필이 수정되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
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
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func saveTapped() {
        let draft = MyPageEditDraft(
            nick: nickField.text ?? "",
            name: nameField.text ?? "",
            introduction: introTextView.text ?? "",
            phone: phoneField.text ?? "",
            hashTagsText: hashTagField.text ?? "",
            profileImageURL: profileImageURL
        )
        saveTappedSubject.send(draft)
    }

    @objc private func changeImageTapped() {
        let uploadVC = MyPageImageUploadViewController(viewModel: viewModel.makeImageUploadViewModel())
        uploadVC.onUploadCompleted = { [weak self] url in
            self?.profileImageURL = url
            self?.profileImageView.kf.setImage(with: url)
            self?.shouldRefreshProfile = true
            self?.shouldForceRefreshImage = true
        }
        navigationController?.pushViewController(uploadVC, animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func refreshTriggered() {
        shouldForceRefreshImage = true
        refreshSubject.send(())
    }

    private func cacheBustedURL(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return url }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "t", value: String(Int(Date().timeIntervalSince1970))))
        components.queryItems = items
        return components.url ?? url
    }
}

extension MyPageEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        introPlaceholderLabel.isHidden = !(textView.text?.isEmpty ?? true)
    }
}
