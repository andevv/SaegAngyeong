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
    var onEditProfileRequested: ((UserProfile?) -> Void)?
    var onPurchaseHistoryRequested: (() -> Void)?
    var onLikedFilterRequested: (() -> Void)?
    var onMyUploadRequested: ((String) -> Void)?
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let nickLabel = UILabel()
    private let introLabel = UILabel()
    private let infoStack = UIStackView()
    private let hashTagStack = UIStackView()

    private let editProfileButton = UIButton(type: .system)
    private let purchaseHistoryButton = UIButton(type: .system)
    private let likedFilterButton = UIButton(type: .system)
    private let myUploadButton = UIButton(type: .system)

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private var currentProfile: UserProfile?

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
        hashTagStack.distribution = .fill
        hashTagStack.setContentHuggingPriority(.required, for: .horizontal)
        hashTagStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        editProfileButton.setTitle("프로필 수정", for: .normal)
        editProfileButton.titleLabel?.font = .pretendard(.medium, size: 12)
        editProfileButton.setTitleColor(.gray30, for: .normal)
        editProfileButton.backgroundColor = .brightTurquoise.withAlphaComponent(0.2)
        editProfileButton.layer.cornerRadius = 12
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)

        purchaseHistoryButton.setTitle("구매내역", for: .normal)
        purchaseHistoryButton.titleLabel?.font = .pretendard(.medium, size: 13)
        purchaseHistoryButton.setTitleColor(.gray30, for: .normal)
        purchaseHistoryButton.backgroundColor = .blackTurquoise
        purchaseHistoryButton.layer.cornerRadius = 12
        purchaseHistoryButton.contentHorizontalAlignment = .left
        purchaseHistoryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        if let image = UIImage(named: "Icon_chevron")?.withRenderingMode(.alwaysTemplate) {
            purchaseHistoryButton.setImage(image, for: .normal)
            purchaseHistoryButton.tintColor = .gray60
            purchaseHistoryButton.semanticContentAttribute = .forceRightToLeft
            purchaseHistoryButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        }
        purchaseHistoryButton.addTarget(self, action: #selector(purchaseHistoryTapped), for: .touchUpInside)

        likedFilterButton.setTitle("좋아요한 필터", for: .normal)
        likedFilterButton.titleLabel?.font = .pretendard(.medium, size: 13)
        likedFilterButton.setTitleColor(.gray30, for: .normal)
        likedFilterButton.backgroundColor = .blackTurquoise
        likedFilterButton.layer.cornerRadius = 12
        likedFilterButton.contentHorizontalAlignment = .left
        likedFilterButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        if let image = UIImage(named: "Icon_chevron")?.withRenderingMode(.alwaysTemplate) {
            likedFilterButton.setImage(image, for: .normal)
            likedFilterButton.tintColor = .gray60
            likedFilterButton.semanticContentAttribute = .forceRightToLeft
            likedFilterButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        }
        likedFilterButton.addTarget(self, action: #selector(likedFilterTapped), for: .touchUpInside)

        myUploadButton.setTitle("내가 만든 필터", for: .normal)
        myUploadButton.titleLabel?.font = .pretendard(.medium, size: 13)
        myUploadButton.setTitleColor(.gray30, for: .normal)
        myUploadButton.backgroundColor = .blackTurquoise
        myUploadButton.layer.cornerRadius = 12
        myUploadButton.contentHorizontalAlignment = .left
        myUploadButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        if let image = UIImage(named: "Icon_chevron")?.withRenderingMode(.alwaysTemplate) {
            myUploadButton.setImage(image, for: .normal)
            myUploadButton.tintColor = .gray60
            myUploadButton.semanticContentAttribute = .forceRightToLeft
            myUploadButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        }
        myUploadButton.addTarget(self, action: #selector(myUploadTapped), for: .touchUpInside)

        [
            profileImageView,
            nameLabel,
            nickLabel,
            introLabel,
            hashTagStack,
            editProfileButton,
            infoStack,
            purchaseHistoryButton,
            likedFilterButton,
            myUploadButton
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
            make.leading.equalToSuperview().inset(20)
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        editProfileButton.snp.makeConstraints { make in
            make.top.equalTo(hashTagStack.snp.bottom).offset(20)
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        infoStack.snp.makeConstraints { make in
            make.top.equalTo(editProfileButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        purchaseHistoryButton.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(16)
            make.leading.trailing.equalTo(editProfileButton)
            make.height.equalTo(48)
        }

        likedFilterButton.snp.makeConstraints { make in
            make.top.equalTo(purchaseHistoryButton.snp.bottom).offset(12)
            make.leading.trailing.equalTo(editProfileButton)
            make.height.equalTo(48)
        }

        myUploadButton.snp.makeConstraints { make in
            make.top.equalTo(likedFilterButton.snp.bottom).offset(12)
            make.leading.trailing.equalTo(editProfileButton)
            make.height.equalTo(48)
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
        currentProfile = profile
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
            profile.hashTags.forEach { hashTag in
                let display = hashTag.hasPrefix("#") ? hashTag : "#\(hashTag)"
                hashTagStack.addArrangedSubview(makeHashTagLabel(text: display))
            }
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
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func editProfileTapped() {
        onEditProfileRequested?(currentProfile)
    }

    @objc private func purchaseHistoryTapped() {
        onPurchaseHistoryRequested?()
    }

    @objc private func likedFilterTapped() {
        onLikedFilterRequested?()
    }

    @objc private func myUploadTapped() {
        guard let profile = currentProfile else {
            presentMessage("프로필 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.")
            return
        }
        onMyUploadRequested?(profile.id)
    }

    private func presentMessage(_ message: String) {
        let alert = UIAlertController(title: "안내", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

}
