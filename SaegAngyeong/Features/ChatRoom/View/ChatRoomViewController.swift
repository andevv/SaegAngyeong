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
import PhotosUI
import UniformTypeIdentifiers

final class ChatRoomViewController: BaseViewController<ChatRoomViewModel> {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputContainer = UIView()
    private let attachButton = UIButton(type: .system)
    private let messageField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var keyboardObservers: [NSObjectProtocol] = []
    private let tokenStore = TokenStore()

    private var items: [ChatRoomItem] = []
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let sendSubject = PassthroughSubject<String, Never>()
    private let uploadFilesSubject = PassthroughSubject<[UploadFileData], Never>()
    private let viewDidDisappearSubject = PassthroughSubject<Void, Never>()
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    private var didInitialScroll = false
    private var needsInitialScroll = false
    private var isRefreshing = false
    private let maxUploadBytes = 5 * 1024 * 1024

    var onImagePreview: (([URL], Int) -> Void)?
    var onFilePreview: ((URL) -> Void)?

    private var imageHeaders: [String: String] {
        var headers: [String: String] = ["SeSACKey": AppConfig.apiKey]
        if let token = tokenStore.accessToken {
            headers["Authorization"] = token
        }
        return headers
    }

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
        if isMovingFromParent || isBeingDismissed {
            tabBarController?.tabBar.isHidden = false
        }
        stopKeyboardObservers()
        if isMovingFromParent || isBeingDismissed {
            viewDidDisappearSubject.send(())
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            tabBarController?.tabBar.isHidden = false
        }
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

        attachButton.setTitle(nil, for: .normal)
        attachButton.setImage(UIImage(systemName: "plus"), for: .normal)
        attachButton.tintColor = .gray30
        attachButton.imageView?.contentMode = .scaleAspectFit
        attachButton.contentHorizontalAlignment = .center
        attachButton.contentVerticalAlignment = .center
        attachButton.backgroundColor = .blackTurquoise
        attachButton.layer.cornerRadius = 16
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)

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
        inputContainer.addSubview(attachButton)
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

        attachButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        messageField.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(attachButton.snp.trailing).offset(8)
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
            uploadFiles: uploadFilesSubject.eraseToAnyPublisher(),
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
                    }
                    self.needsInitialScroll = true
                    DispatchQueue.main.async { [weak self] in
                        guard let self, self.needsInitialScroll else { return }
                        self.scrollToBottomSync()
                        self.needsInitialScroll = false
                        self.didInitialScroll = true
                    }
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

    @objc private func attachTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "사진 선택", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        sheet.addAction(UIAlertAction(title: "PDF 선택", style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        })
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(sheet, animated: true)
    }

    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 5
        config.filter = .any(of: [.images, .livePhotos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = self
        present(picker, animated: true)
    }

    private func uploadSelectedFiles(_ files: [UploadFileData]) {
        guard files.isEmpty == false else { return }
        if files.count > 5 {
            presentAlert(title: "업로드 실패", message: "최대 5개까지 업로드할 수 있어요.")
            return
        }
        for file in files where file.data.count > maxUploadBytes {
            presentAlert(title: "업로드 실패", message: "파일 용량은 5MB 이하만 가능합니다.")
            return
        }
        uploadFilesSubject.send(files)
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
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
        guard items.isEmpty == false else { return }
        tableView.layoutIfNeeded()
        let lastRow = items.count - 1
        let indexPath = IndexPath(row: lastRow, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
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

extension ChatRoomViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard results.isEmpty == false else { return }
        var uploads: [UploadFileData] = []
        let group = DispatchGroup()
        for result in results {
            let provider = result.itemProvider
            group.enter()
            if provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.gif.identifier) { data, _ in
                    if let data {
                        uploads.append(UploadFileData(data: data, fileName: "chat_image_\(UUID().uuidString).gif", mimeType: "image/gif"))
                    }
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.png.identifier) { data, _ in
                    if let data {
                        uploads.append(UploadFileData(data: data, fileName: "chat_image_\(UUID().uuidString).png", mimeType: "image/png"))
                    }
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.jpeg.identifier) { data, _ in
                    if let data {
                        uploads.append(UploadFileData(data: data, fileName: "chat_image_\(UUID().uuidString).jpg", mimeType: "image/jpeg"))
                    }
                    group.leave()
                }
            } else {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage, let data = image.jpegData(compressionQuality: 0.85) {
                        uploads.append(UploadFileData(data: data, fileName: "chat_image_\(UUID().uuidString).jpg", mimeType: "image/jpeg"))
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.uploadSelectedFiles(uploads)
        }
    }
}

extension ChatRoomViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let uploads: [UploadFileData] = urls.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            let name = url.lastPathComponent
            return UploadFileData(data: data, fileName: name, mimeType: "application/pdf")
        }
        uploadSelectedFiles(uploads)
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
            cell.configure(with: message, headers: imageHeaders)
            cell.onImageTap = { [weak self] urls, index in
                self?.onImagePreview?(urls, index)
            }
            cell.onFileTap = { [weak self] url in
                self?.onFilePreview?(url)
            }
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
    private let contentStack = UIStackView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let attachmentGridView = ChatAttachmentGridView()
    private let fileRowView = UIStackView()
    private let fileIconView = UIImageView()
    private let fileNameLabel = UILabel()
    private let timeLabel = UILabel()
    private let avatarImageView = UIImageView()
    private let bubbleInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    private var imageURLs: [URL] = []
    private var filePreviewURL: URL?

    var onImageTap: (([URL], Int) -> Void)?
    var onFileTap: ((URL) -> Void)?
    private var fileRowMinHeightConstraint: Constraint?
    private var fileRowFixedWidthConstraint: Constraint?
    private var fileRowFixedHeightConstraint: Constraint?

    private var leadingConstraint: Constraint?
    private var trailingConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.layer.cornerRadius = 16
        bubbleView.backgroundColor = .blackTurquoise

        contentStack.axis = .vertical
        contentStack.spacing = 6
        contentStack.alignment = .fill

        nameLabel.font = .pretendard(.medium, size: 10)
        nameLabel.textColor = .gray60

        messageLabel.font = .pretendard(.regular, size: 13)
        messageLabel.textColor = .gray30
        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(.required, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        attachmentGridView.clipsToBounds = true
        attachmentGridView.layer.cornerRadius = 12
        attachmentGridView.backgroundColor = .black

        fileRowView.axis = .horizontal
        fileRowView.spacing = 8
        fileRowView.alignment = .center
        fileRowView.isLayoutMarginsRelativeArrangement = true
        fileRowView.layoutMargins = .zero
        fileRowView.backgroundColor = .clear
        fileRowView.layer.cornerRadius = 0
        fileRowView.isUserInteractionEnabled = true

        fileIconView.image = UIImage(systemName: "doc.fill")
        fileIconView.tintColor = .gray30
        fileIconView.setContentHuggingPriority(.required, for: .horizontal)

        fileNameLabel.font = .pretendard(.regular, size: 12)
        fileNameLabel.textColor = .gray30
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle

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
        bubbleView.addSubview(contentStack)
        fileRowView.addArrangedSubview(fileIconView)
        fileRowView.addArrangedSubview(fileNameLabel)
        contentStack.addArrangedSubview(attachmentGridView)
        contentStack.addArrangedSubview(fileRowView)
        contentStack.addArrangedSubview(messageLabel)

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(32)
        }

        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
        }

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(bubbleInset)
        }

        attachmentGridView.snp.makeConstraints { make in
            make.height.equalTo(180)
        }

        fileIconView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }

        fileRowView.snp.makeConstraints { make in
            fileRowMinHeightConstraint = make.height.greaterThanOrEqualTo(0).constraint
            fileRowFixedWidthConstraint = make.width.equalTo(240).constraint
            fileRowFixedHeightConstraint = make.height.equalTo(56).constraint
        }
        fileRowFixedWidthConstraint?.deactivate()
        fileRowFixedHeightConstraint?.deactivate()

        let fileTap = UITapGestureRecognizer(target: self, action: #selector(handleFileTap))
        fileRowView.addGestureRecognizer(fileTap)

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
        attachmentGridView.prepareForReuse()
        fileNameLabel.text = nil
        self.imageURLs = []
        filePreviewURL = nil
        onImageTap = nil
        onFileTap = nil
    }

    func configure(with item: ChatMessageViewData, headers: [String: String]) {
        let hasFile = item.fileURLs.isEmpty == false
        let fileURL = item.fileURLs.first
        let imageFileURLs = item.fileURLs.filter { url in
            ["jpg", "jpeg", "png", "gif"].contains(url.pathExtension.lowercased())
        }
        let isImageBundle = hasFile && imageFileURLs.count == item.fileURLs.count
        let isFileBundle = hasFile && !isImageBundle
        let trimmedText = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isPlaceholderText = trimmedText == "사진을 보냈습니다." || trimmedText == "파일을 보냈습니다."
        messageLabel.text = item.text
        timeLabel.text = item.timeText
        let isMine = item.isMine
        nameLabel.text = isMine ? nil : item.senderName
        nameLabel.isHidden = !(item.showName)
        avatarImageView.isHidden = !(item.showAvatar)
        timeLabel.isHidden = !(item.showTime)
        let isImageOnly = isImageBundle && (isPlaceholderText || trimmedText.isEmpty)
        bubbleView.backgroundColor = (isImageBundle || isFileBundle) ? .clear : (isMine ? UIColor.brightTurquoise.withAlphaComponent(0.9) : .blackTurquoise)
        messageLabel.textColor = .gray30
        contentStack.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(isImageBundle ? .zero : bubbleInset)
        }
        attachmentGridView.layer.cornerRadius = isImageBundle ? 16 : 12

        if hasFile {
            attachmentGridView.isHidden = !isImageBundle
            fileRowView.isHidden = isImageBundle
            if isImageBundle {
                self.imageURLs = imageFileURLs
                attachmentGridView.configure(urls: imageFileURLs, headers: headers)
                attachmentGridView.onTap = { [weak self] index in
                    guard let self, index < self.imageURLs.count else { return }
                    self.onImageTap?(self.imageURLs, index)
                }
                filePreviewURL = nil
            } else {
                fileNameLabel.text = fileURL?.lastPathComponent ?? "파일"
                self.imageURLs = []
                attachmentGridView.onTap = nil
                self.filePreviewURL = fileURL
            }
            messageLabel.isHidden = isImageOnly || isPlaceholderText || trimmedText.isEmpty
            updateFileRowStyle(isFile: isFileBundle, fileURL: fileURL)
        } else {
            attachmentGridView.isHidden = true
            fileRowView.isHidden = true
            messageLabel.isHidden = trimmedText.isEmpty
            self.imageURLs = []
            filePreviewURL = nil
            attachmentGridView.onTap = nil
            updateFileRowStyle(isFile: false, fileURL: nil)
        }
        let groupSpacing: CGFloat = item.isGroupStart ? 4 : 0
        let bubbleTopOffset: CGFloat = groupSpacing
        let nameTopOffset: CGFloat = 4 + groupSpacing
        let bubbleWidthMultiplier: CGFloat = 0.7
        let bubbleSideInset: CGFloat = isImageBundle ? 12 : (isFileBundle ? 10 : 16)
        let bubbleMinLeading: CGFloat = isImageBundle ? 24 : (isFileBundle ? 88 : 72)
        let bubbleMaxTrailing: CGFloat = isImageBundle ? 24 : (isFileBundle ? 88 : 72)
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
                make.trailing.equalToSuperview().inset(bubbleSideInset)
                make.leading.greaterThanOrEqualToSuperview().offset(bubbleMinLeading)
                if isImageBundle {
                    make.width.equalToSuperview().multipliedBy(bubbleWidthMultiplier)
                } else {
                    make.width.lessThanOrEqualToSuperview().multipliedBy(bubbleWidthMultiplier)
                }
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
                make.trailing.lessThanOrEqualToSuperview().inset(bubbleMaxTrailing)
                if isImageBundle {
                    make.width.equalToSuperview().multipliedBy(bubbleWidthMultiplier)
                } else {
                    make.width.lessThanOrEqualToSuperview().multipliedBy(bubbleWidthMultiplier)
                }
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.trailing).offset(6)
                make.bottom.equalTo(bubbleView).offset(-2)
            }
            if let url = item.avatarURL {
                KingfisherHelper.setImage(
                    avatarImageView,
                    url: url,
                    headers: headers,
                    placeholder: UIImage(named: "Profile_Empty"),
                    logLabel: "chat-avatar"
                )
            } else {
                avatarImageView.image = UIImage(named: "Profile_Empty")
            }
        }
        setNeedsLayout()
    }

    @objc private func handleFileTap() {
        guard let url = filePreviewURL else { return }
        onFileTap?(url)
    }

    private func updateFileRowStyle(isFile: Bool, fileURL: URL?) {
        guard isFile else {
            fileRowView.layoutMargins = .zero
            fileRowView.backgroundColor = .clear
            fileRowView.layer.cornerRadius = 0
            fileNameLabel.numberOfLines = 1
            fileNameLabel.font = .pretendard(.regular, size: 12)
            fileRowMinHeightConstraint?.update(offset: 0)
            return
        }
        let isPDF = fileURL?.pathExtension.lowercased() == "pdf"
        if isPDF {
            fileRowView.layoutMargins = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            fileRowView.backgroundColor = .gray90
            fileRowView.layer.cornerRadius = 12
            fileNameLabel.numberOfLines = 2
            fileNameLabel.font = .pretendard(.regular, size: 13)
            fileRowMinHeightConstraint?.update(offset: 0)
            fileRowFixedWidthConstraint?.activate()
            fileRowFixedHeightConstraint?.activate()
        } else {
            fileRowView.layoutMargins = .zero
            fileRowView.backgroundColor = .clear
            fileRowView.layer.cornerRadius = 0
            fileNameLabel.numberOfLines = 1
            fileNameLabel.font = .pretendard(.regular, size: 12)
            fileRowMinHeightConstraint?.update(offset: 0)
            fileRowFixedWidthConstraint?.deactivate()
            fileRowFixedHeightConstraint?.deactivate()
        }
    }
}

private final class ChatAttachmentGridView: UIView {
    private enum LayoutCount: Int {
        case one = 1
        case two = 2
        case three = 3
        case four = 4
        case five = 5
    }

    private let spacing: CGFloat = 2
    private let imageViews: [UIImageView] = (0..<5).map { _ in UIImageView() }
    private let overlayView = UIView()
    private let overlayLabel = UILabel()
    private var currentLayout: LayoutCount?
    var onTap: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        imageViews.forEach { imageView in
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 10
            imageView.backgroundColor = .black
            imageView.isUserInteractionEnabled = true
        }
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.isUserInteractionEnabled = false
        overlayLabel.font = .pretendard(.medium, size: 16)
        overlayLabel.textColor = .white
        overlayLabel.textAlignment = .center
        overlayView.addSubview(overlayLabel)
        overlayLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        configureTapHandlers()
        prepareForReuse()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        currentLayout = nil
        imageViews.forEach { imageView in
            imageView.image = nil
            imageView.isHidden = true
        }
        overlayView.removeFromSuperview()
        overlayLabel.text = nil
        overlayView.isHidden = true
    }

    func configure(urls: [URL], headers: [String: String]) {
        guard let layout = LayoutCount(rawValue: min(urls.count, imageViews.count)) else {
            prepareForReuse()
            return
        }
        if layout != currentLayout {
            rebuildLayout(for: layout)
        }
        currentLayout = layout

        let visibleCount: Int
        switch layout {
        case .five:
            visibleCount = 4
        default:
            visibleCount = min(urls.count, imageViews.count)
        }
        for (index, imageView) in imageViews.enumerated() {
            let isVisible = index < visibleCount
            imageView.isHidden = !isVisible
            if isVisible {
                KingfisherHelper.setImage(
                    imageView,
                    url: urls[index],
                    headers: headers,
                    placeholder: nil,
                    logLabel: "chat-attachment"
                )
            }
        }
        updateOverlay(totalCount: urls.count)
    }

    private func rebuildLayout(for layout: LayoutCount) {
        subviews.forEach { $0.removeFromSuperview() }
        overlayView.removeFromSuperview()

        switch layout {
        case .one:
            addSubview(imageViews[0])
            imageViews[0].snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        case .two:
            let stack = makeStack(axis: .horizontal, views: [imageViews[0], imageViews[1]])
            addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        case .three:
            let rightStack = makeStack(axis: .vertical, views: [imageViews[1], imageViews[2]])
            let container = makeStack(axis: .horizontal, views: [imageViews[0], rightStack])
            container.distribution = .fill
            addSubview(container)
            container.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            imageViews[0].snp.makeConstraints { make in
                make.width.equalTo(rightStack.snp.width).multipliedBy(2.0)
            }
        case .four, .five:
            let topRow = makeStack(axis: .horizontal, views: [imageViews[0], imageViews[1]])
            let bottomRow = makeStack(axis: .horizontal, views: [imageViews[2], imageViews[3]])
            let container = makeStack(axis: .vertical, views: [topRow, bottomRow])
            addSubview(container)
            container.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    private func updateOverlay(totalCount: Int) {
        let extraCount = totalCount - 4
        if extraCount > 0 {
            let targetView = imageViews[3]
            targetView.addSubview(overlayView)
            overlayView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            overlayLabel.text = "+\(extraCount)"
            overlayView.isHidden = false
        } else {
            overlayView.removeFromSuperview()
            overlayLabel.text = nil
            overlayView.isHidden = true
        }
    }

    private func makeStack(axis: NSLayoutConstraint.Axis, views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = axis
        stack.spacing = spacing
        stack.distribution = .fillEqually
        return stack
    }

    private func configureTapHandlers() {
        for (index, imageView) in imageViews.enumerated() {
            imageView.tag = index
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
            imageView.addGestureRecognizer(tap)
        }
    }

    @objc private func handleImageTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        onTap?(view.tag)
    }
}
