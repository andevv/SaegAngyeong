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
    var onMyChattingListRequested: (() -> Void)?
    var onStreamingRequested: (() -> Void)?
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
    private let myChattingListButton = UIButton(type: .system)
    private let streamingButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)

    private let activitySectionTitleLabel = UILabel()
    private let activitySectionContainer = UIView()
    private let activitySectionStack = UIStackView()

    private let contentSectionTitleLabel = UILabel()
    private let contentSectionContainer = UIView()
    private let contentSectionStack = UIStackView()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let logoutSubject = PassthroughSubject<Void, Never>()
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

        configureSection(
            titleLabel: activitySectionTitleLabel,
            container: activitySectionContainer,
            stack: activitySectionStack,
            title: "나의 활동"
        )
        configureSection(
            titleLabel: contentSectionTitleLabel,
            container: contentSectionContainer,
            stack: contentSectionStack,
            title: "내 콘텐츠"
        )
        purchaseHistoryButton.setTitle("구매내역", for: .normal)
        purchaseHistoryButton.titleLabel?.font = .pretendard(.medium, size: 13)
        purchaseHistoryButton.setTitleColor(.gray30, for: .normal)
        purchaseHistoryButton.backgroundColor = .blackTurquoise
        purchaseHistoryButton.layer.cornerRadius = 12
        purchaseHistoryButton.contentHorizontalAlignment = .left
        purchaseHistoryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        purchaseHistoryButton.addTarget(self, action: #selector(purchaseHistoryTapped), for: .touchUpInside)

        likedFilterButton.setTitle("좋아요한 필터", for: .normal)
        likedFilterButton.titleLabel?.font = .pretendard(.medium, size: 13)
        likedFilterButton.setTitleColor(.gray30, for: .normal)
        likedFilterButton.backgroundColor = .blackTurquoise
        likedFilterButton.layer.cornerRadius = 12
        likedFilterButton.contentHorizontalAlignment = .left
        likedFilterButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        likedFilterButton.addTarget(self, action: #selector(likedFilterTapped), for: .touchUpInside)

        myUploadButton.setTitle("내가 만든 필터", for: .normal)
        myUploadButton.titleLabel?.font = .pretendard(.medium, size: 13)
        myUploadButton.setTitleColor(.gray30, for: .normal)
        myUploadButton.backgroundColor = .blackTurquoise
        myUploadButton.layer.cornerRadius = 12
        myUploadButton.contentHorizontalAlignment = .left
        myUploadButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        myUploadButton.addTarget(self, action: #selector(myUploadTapped), for: .touchUpInside)

        myChattingListButton.setTitle("나의 채팅 목록", for: .normal)
        myChattingListButton.titleLabel?.font = .pretendard(.medium, size: 13)
        myChattingListButton.setTitleColor(.gray30, for: .normal)
        myChattingListButton.backgroundColor = .blackTurquoise
        myChattingListButton.layer.cornerRadius = 12
        myChattingListButton.contentHorizontalAlignment = .left
        myChattingListButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        myChattingListButton.addTarget(self, action: #selector(myChattingListTapped), for: .touchUpInside)

        streamingButton.setTitle("비디오 스트리밍", for: .normal)
        streamingButton.titleLabel?.font = .pretendard(.medium, size: 13)
        streamingButton.setTitleColor(.gray30, for: .normal)
        streamingButton.backgroundColor = .blackTurquoise
        streamingButton.layer.cornerRadius = 12
        streamingButton.contentHorizontalAlignment = .left
        streamingButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        streamingButton.addTarget(self, action: #selector(streamingTapped), for: .touchUpInside)

        logoutButton.setTitle("로그아웃", for: .normal)
        logoutButton.titleLabel?.font = .pretendard(.medium, size: 13)
        logoutButton.setTitleColor(.gray60, for: .normal)
        logoutButton.backgroundColor = .gray15.withAlphaComponent(0.2)
        logoutButton.layer.cornerRadius = 12
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.borderColor = UIColor.gray90.withAlphaComponent(0.2).cgColor
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)

        [
            profileImageView,
            nameLabel,
            nickLabel,
            introLabel,
            hashTagStack,
            editProfileButton,
            infoStack,
            activitySectionTitleLabel,
            activitySectionContainer,
            contentSectionTitleLabel,
            contentSectionContainer,
            logoutButton
        ].forEach { contentView.addSubview($0) }

        addButtonsWithSeparators([purchaseHistoryButton, likedFilterButton], to: activitySectionStack)
        addButtonsWithSeparators([myUploadButton, myChattingListButton, streamingButton], to: contentSectionStack)

        [purchaseHistoryButton, likedFilterButton, myUploadButton, myChattingListButton, streamingButton, logoutButton].forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(44)
            }
        }
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

        activitySectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        activitySectionContainer.snp.makeConstraints { make in
            make.top.equalTo(activitySectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        contentSectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(activitySectionContainer.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        contentSectionContainer.snp.makeConstraints { make in
            make.top.equalTo(contentSectionTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        logoutButton.snp.makeConstraints { make in
            make.top.equalTo(contentSectionContainer.snp.bottom).offset(16)
            make.leading.trailing.equalTo(editProfileButton)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    override func bindViewModel() {
        let input = MyPageViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            refresh: refreshSubject.eraseToAnyPublisher(),
            logoutTapped: logoutSubject.eraseToAnyPublisher()
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

        output.logoutCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.presentLogoutCompleted()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .networkRetryRequested)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSubject.send(())
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

        let placeholder = UIImage(named: "Profile_Empty")
        if let url = profile.profileImageURL {
            KingfisherHelper.setImage(
                profileImageView,
                url: url,
                headers: viewModel.imageHeaders,
                placeholder: placeholder,
                logLabel: "mypage-profile"
            )
        } else {
            profileImageView.image = placeholder
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

    private func configureSection(titleLabel: UILabel, container: UIView, stack: UIStackView, title: String) {
        titleLabel.text = title
        titleLabel.textColor = .gray75
        titleLabel.font = .pretendard(.medium, size: 12)

        container.backgroundColor = .blackTurquoise
        container.layer.cornerRadius = 14

        stack.axis = .vertical
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func addButtonsWithSeparators(_ buttons: [UIButton], to stack: UIStackView) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, button) in buttons.enumerated() {
            stack.addArrangedSubview(button)
            if index < buttons.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor.gray90.withAlphaComponent(0.2)
                separator.snp.makeConstraints { make in
                    make.height.equalTo(1)
                }
                stack.addArrangedSubview(separator)
            }
        }
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

    @objc private func myChattingListTapped() {
        onMyChattingListRequested?()
    }

    @objc private func streamingTapped() {
        onStreamingRequested?()
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "로그아웃", message: "정말 로그아웃 하시겠어요?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { [weak self] _ in
            self?.logoutSubject.send(())
        }))
        present(alert, animated: true)
    }

    private func presentMessage(_ message: String) {
        let alert = UIAlertController(title: "안내", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func presentLogoutCompleted() {
        let alert = UIAlertController(title: "로그아웃", message: "로그아웃이 완료되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            NotificationCenter.default.post(name: .tokenInvalidated, object: nil)
        }))
        present(alert, animated: true)
    }

}
