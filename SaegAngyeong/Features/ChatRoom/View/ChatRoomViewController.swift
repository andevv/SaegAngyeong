//
//  ChatRoomViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/6/26.
//

import UIKit
import SnapKit
import Combine
import Kingfisher

final class ChatRoomViewController: BaseViewController<ChatRoomViewModel> {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputContainer = UIView()
    private let messageField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var keyboardObservers: [NSObjectProtocol] = []

    private var items: [ChatRoomItem] = []
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let sendSubject = PassthroughSubject<String, Never>()
    private let viewDidDisappearSubject = PassthroughSubject<Void, Never>()
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    private var didInitialScroll = false
    private var isRefreshing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        view.backgroundColor = .black
        viewDidLoadSubject.send(())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startKeyboardObservers()
        updateMessageInsets(keyboardHeight: 0)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        stopKeyboardObservers()
        viewDidDisappearSubject.send(())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.gray60
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray60
        navigationController?.navigationBar.barStyle = .black
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func configureUI() {
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseID)
        tableView.register(ChatDateSeparatorCell.self, forCellReuseIdentifier: ChatDateSeparatorCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.keyboardDismissMode = .none

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .gray60
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        inputContainer.backgroundColor = .black

        messageField.textColor = .gray30
        messageField.font = .pretendard(.regular, size: 13)
        messageField.attributedPlaceholder = NSAttributedString(
            string: "메시지를 입력하세요.",
            attributes: [.foregroundColor: UIColor.gray60]
        )
        messageField.backgroundColor = .blackTurquoise
        messageField.layer.cornerRadius = 18
        messageField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        messageField.leftViewMode = .always
        messageField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        messageField.rightViewMode = .always

        sendButton.setTitle("전송", for: .normal)
        sendButton.titleLabel?.font = .pretendard(.medium, size: 13)
        sendButton.setTitleColor(.gray30, for: .normal)
        sendButton.backgroundColor = .brightTurquoise
        sendButton.layer.cornerRadius = 14
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        view.addSubview(tableView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(messageField)
        inputContainer.addSubview(sendButton)

        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    override func configureLayout() {
        inputContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
            make.height.equalTo(64)
        }

        messageField.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(sendButton.snp.leading).offset(-12)
            make.height.equalTo(36)
        }

        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(32)
        }

        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(inputContainer.snp.top)
        }
    }

    override func bindViewModel() {
        let input = ChatRoomViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            refresh: refreshSubject.eraseToAnyPublisher(),
            sendText: sendSubject.eraseToAnyPublisher(),
            viewDidDisappear: viewDidDisappearSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                self?.navigationItem.title = title
            }
            .store(in: &cancellables)

        output.messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.items = items
                self.tableView.refreshControl?.endRefreshing()
                if self.didInitialScroll == false, items.isEmpty == false {
                    UIView.performWithoutAnimation {
                        self.tableView.reloadData()
                        self.tableView.layoutIfNeeded()
                        self.scrollToBottomSync()
                    }
                    self.didInitialScroll = true
                } else {
                    self.tableView.reloadData()
                    if items.isEmpty == false {
                        self.scrollToBottom()
                    }
                }
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.tableView.refreshControl?.endRefreshing()
                self?.presentError(error)
            }
            .store(in: &cancellables)

        viewModel.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else { return }
                if isLoading == false {
                    self.tableView.refreshControl?.endRefreshing()
                    if self.isRefreshing {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        self.isRefreshing = false
                    }
                }
            }
            .store(in: &cancellables)
    }

    @objc private func handleRefresh() {
        isRefreshing = true
        refreshSubject.send(())
    }

    @objc private func sendTapped() {
        let text = messageField.text ?? ""
        messageField.text = ""
        sendSubject.send(text)
    }

    private func scrollToBottom() {
        guard items.count > 0 else { return }
        let lastRow = items.count - 1
        tableView.scrollToRow(at: IndexPath(row: lastRow, section: 0), at: .bottom, animated: true)
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func startKeyboardObservers() {
        guard keyboardObservers.isEmpty else { return }
        let center = NotificationCenter.default
        let willShow = center.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, isShowing: true)
        }
        let willHide = center.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, isShowing: false)
        }
        keyboardObservers = [willShow, willHide]
    }

    private func stopKeyboardObservers() {
        keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
        keyboardObservers.removeAll()
    }

    private func handleKeyboard(notification: Notification, isShowing: Bool) {
        guard let info = notification.userInfo,
              let frameValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        let keyboardFrame = frameValue.cgRectValue
        let keyboardHeight = isShowing ? keyboardFrame.height - view.safeAreaInsets.bottom : 0
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.updateMessageInsets(keyboardHeight: keyboardHeight)
            if isShowing {
                self.scrollToBottomSync()
            }
        }
    }

    private func updateMessageInsets(keyboardHeight: CGFloat) {
        view.layoutIfNeeded()
        let bottomInset: CGFloat = 12
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func scrollToBottomSync() {
        tableView.layoutIfNeeded()
        let contentHeight = tableView.contentSize.height
        let boundsHeight = tableView.bounds.height
        let inset = tableView.adjustedContentInset
        let maxOffsetY = max(-inset.top, contentHeight - boundsHeight + inset.bottom)
        tableView.setContentOffset(CGPoint(x: 0, y: maxOffsetY), animated: false)
    }
}

extension ChatRoomViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: inputContainer) == true {
            return false
        }
        return true
    }
}

extension ChatRoomViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .message(let message):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.reuseID, for: indexPath) as? ChatMessageCell else {
                return UITableViewCell()
            }
            cell.configure(with: message)
            return cell
        case .date(let text):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatDateSeparatorCell.reuseID, for: indexPath) as? ChatDateSeparatorCell else {
                return UITableViewCell()
            }
            cell.configure(text: text)
            return cell
        }
    }
}

private final class ChatDateSeparatorCell: UITableViewCell {
    static let reuseID = "ChatDateSeparatorCell"

    private let backgroundContainer = UIView()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        backgroundContainer.backgroundColor = .gray90.withAlphaComponent(0.6)
        backgroundContainer.layer.cornerRadius = 10

        dateLabel.font = .pretendard(.regular, size: 11)
        dateLabel.textColor = .gray60
        dateLabel.textAlignment = .center

        contentView.addSubview(backgroundContainer)
        backgroundContainer.addSubview(dateLabel)

        backgroundContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        dateLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String) {
        dateLabel.text = text
    }
}

private final class ChatMessageCell: UITableViewCell {
    static let reuseID = "ChatMessageCell"

    private let bubbleView = UIView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let avatarImageView = UIImageView()

    private var leadingConstraint: Constraint?
    private var trailingConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.layer.cornerRadius = 16
        bubbleView.backgroundColor = .blackTurquoise

        nameLabel.font = .pretendard(.medium, size: 10)
        nameLabel.textColor = .gray60

        messageLabel.font = .pretendard(.regular, size: 13)
        messageLabel.textColor = .gray30
        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(.required, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        timeLabel.font = .pretendard(.regular, size: 10)
        timeLabel.textColor = .gray60

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 16
        avatarImageView.backgroundColor = .gray15

        contentView.addSubview(bubbleView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(avatarImageView)
        bubbleView.addSubview(messageLabel)

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(32)
        }

        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
        }

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        timeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(bubbleView.snp.leading).offset(-6)
            make.bottom.equalTo(bubbleView).offset(-2)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
    }

    func configure(with item: ChatMessageViewData) {
        messageLabel.text = item.text.isEmpty ? "사진을 보냈습니다." : item.text
        timeLabel.text = item.timeText
        let isMine = item.isMine
        nameLabel.text = isMine ? nil : item.senderName
        nameLabel.isHidden = !(item.showName)
        avatarImageView.isHidden = !(item.showAvatar)
        timeLabel.isHidden = !(item.showTime)
        bubbleView.backgroundColor = isMine ? UIColor.brightTurquoise.withAlphaComponent(0.9) : .blackTurquoise
        messageLabel.textColor = isMine ? .gray30 : .gray30
        let groupSpacing: CGFloat = item.isGroupStart ? 4 : 0
        let bubbleTopOffset: CGFloat = groupSpacing
        let nameTopOffset: CGFloat = 4 + groupSpacing
        if isMine {
            avatarImageView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.width.height.equalTo(32)
            }
            nameLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(nameTopOffset)
                make.trailing.equalTo(bubbleView)
            }
            bubbleView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(bubbleTopOffset)
                make.bottom.equalToSuperview().offset(-6)
                make.trailing.equalToSuperview().inset(16)
                make.leading.greaterThanOrEqualToSuperview().offset(72)
                make.width.lessThanOrEqualToSuperview().multipliedBy(0.7)
            }
            timeLabel.snp.remakeConstraints { make in
                make.trailing.equalTo(bubbleView.snp.leading).offset(-6)
                make.bottom.equalTo(bubbleView).offset(-2)
            }
        } else {
            avatarImageView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.top.equalToSuperview().offset(4)
                make.width.height.equalTo(32)
            }
            nameLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(nameTopOffset)
                make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
                make.trailing.lessThanOrEqualToSuperview().inset(72)
            }
            bubbleView.snp.remakeConstraints { make in
                if item.showName {
                    make.top.equalTo(nameLabel.snp.bottom).offset(4)
                } else {
                    make.top.equalToSuperview().offset(bubbleTopOffset)
                }
                make.bottom.equalToSuperview().offset(-6)
                make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
                make.trailing.lessThanOrEqualToSuperview().inset(72)
                make.width.lessThanOrEqualToSuperview().multipliedBy(0.7)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.trailing).offset(6)
                make.bottom.equalTo(bubbleView).offset(-2)
            }
            if let url = item.avatarURL {
                KingfisherHelper.setImage(
                    avatarImageView,
                    url: url,
                    headers: [:],
                    placeholder: UIImage(named: "Profile_Empty"),
                    logLabel: "chat-avatar"
                )
            } else {
                avatarImageView.image = UIImage(named: "Profile_Empty")
            }
        }
        setNeedsLayout()
    }
}
