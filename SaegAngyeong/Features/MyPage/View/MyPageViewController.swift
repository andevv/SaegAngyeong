//
//  MyPageViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/30/25.
//

import UIKit
import SnapKit
import Combine
import Kingfisher

final class MyPageViewController: BaseViewController<MyPageViewModel> {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let nickLabel = UILabel()
    private let introLabel = UILabel()
    private let infoStack = UIStackView()
    private let hashTagStack = UIStackView()

    private let editProfileButton = UIButton(type: .system)
    private let uploadImageButton = UIButton(type: .system)

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()

    override init(viewModel: MyPageViewModel) {
        super.init(viewModel: viewModel)
        tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "Profile_Empty"),
            selectedImage: UIImage(named: "Profile_Fill")
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        viewDidLoadSubject.send(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSubject.send(())
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
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func configureUI() {
        let titleLabel = UILabel()
        titleLabel.text = "MY PAGE"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 40
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.gray90.withAlphaComponent(0.3).cgColor
        profileImageView.backgroundColor = .blackTurquoise

        nameLabel.font = .mulgyeol(.bold, size: 20)
        nameLabel.textColor = .gray30

        nickLabel.font = .pretendard(.medium, size: 12)
        nickLabel.textColor = .gray75

        introLabel.font = .pretendard(.regular, size: 12)
        introLabel.textColor = .gray60
        introLabel.numberOfLines = 0

        infoStack.axis = .vertical
        infoStack.spacing = 8

        hashTagStack.axis = .horizontal
        hashTagStack.spacing = 8
        hashTagStack.alignment = .leading

        editProfileButton.setTitle("프로필 수정", for: .normal)
        editProfileButton.titleLabel?.font = .pretendard(.medium, size: 12)
        editProfileButton.setTitleColor(.gray30, for: .normal)
        editProfileButton.backgroundColor = .brightTurquoise.withAlphaComponent(0.2)
        editProfileButton.layer.cornerRadius = 12
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)

        uploadImageButton.setTitle("프로필 이미지 변경", for: .normal)
        uploadImageButton.titleLabel?.font = .pretendard(.medium, size: 12)
        uploadImageButton.setTitleColor(.gray60, for: .normal)
        uploadImageButton.layer.cornerRadius = 12
        uploadImageButton.layer.borderWidth = 1
        uploadImageButton.layer.borderColor = UIColor.gray90.withAlphaComponent(0.4).cgColor
        uploadImageButton.addTarget(self, action: #selector(uploadImageTapped), for: .touchUpInside)

        [
            profileImageView,
            nameLabel,
            nickLabel,
            introLabel,
            hashTagStack,
            editProfileButton,
            uploadImageButton,
            infoStack
        ].forEach { contentView.addSubview($0) }
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

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView)
            make.leading.equalTo(profileImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(20)
        }

        nickLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalTo(nameLabel)
        }

        introLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        hashTagStack.snp.makeConstraints { make in
            make.top.equalTo(introLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        editProfileButton.snp.makeConstraints { make in
            make.top.equalTo(hashTagStack.snp.bottom).offset(20)
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        uploadImageButton.snp.makeConstraints { make in
            make.top.equalTo(editProfileButton.snp.bottom).offset(10)
            make.leading.trailing.equalTo(editProfileButton)
            make.height.equalTo(44)
        }

        infoStack.snp.makeConstraints { make in
            make.top.equalTo(uploadImageButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    override func bindViewModel() {
        let input = MyPageViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            refresh: refreshSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.profile
            .sink { [weak self] profile in
                self?.applyProfile(profile)
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func applyProfile(_ profile: UserProfile?) {
        guard let profile else { return }
        nameLabel.text = profile.name ?? profile.nick
        nickLabel.text = profile.nick
        introLabel.text = profile.introduction?.isEmpty == false ? profile.introduction : "소개가 아직 없습니다."

        infoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let email = profile.email ?? "-"
        let phone = profile.phoneNumber ?? "-"
        infoStack.addArrangedSubview(makeInfoRow(title: "이메일", value: email))
        infoStack.addArrangedSubview(makeInfoRow(title: "전화번호", value: phone))

        hashTagStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if profile.hashTags.isEmpty {
            hashTagStack.addArrangedSubview(makeHashTagLabel(text: "#태그없음"))
        } else {
            profile.hashTags.forEach { hashTagStack.addArrangedSubview(makeHashTagLabel(text: $0)) }
        }

        if let url = profile.profileImageURL {
            profileImageView.kf.setImage(with: url)
        } else {
            profileImageView.image = UIImage(named: "Profile_Empty")
        }
    }

    private func makeInfoRow(title: String, value: String) -> UIView {
        let container = UIView()
        let titleLabel = UILabel()
        let valueLabel = UILabel()

        titleLabel.text = title
        titleLabel.font = .pretendard(.medium, size: 12)
        titleLabel.textColor = .gray75

        valueLabel.text = value
        valueLabel.font = .pretendard(.regular, size: 12)
        valueLabel.textColor = .gray60
        valueLabel.numberOfLines = 0

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.equalTo(60)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        return container
    }

    private func makeHashTagLabel(text: String) -> UILabel {
        let label = PaddingLabel(padding: UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        label.text = text
        label.font = .pretendard(.medium, size: 11)
        label.textColor = .gray60
        label.backgroundColor = .gray15.withAlphaComponent(0.15)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.gray90.withAlphaComponent(0.25).cgColor
        return label
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func editProfileTapped() {
        let editVC = MyPageEditViewController()
        navigationController?.pushViewController(editVC, animated: true)
    }

    @objc private func uploadImageTapped() {
        let uploadVC = MyPageImageUploadViewController()
        navigationController?.pushViewController(uploadVC, animated: true)
    }
}
