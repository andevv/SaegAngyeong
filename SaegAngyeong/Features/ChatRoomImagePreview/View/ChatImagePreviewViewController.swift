//
//  ChatRoomImagePreviewViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/12/26.
//

import UIKit
import SnapKit

final class ChatRoomImagePreviewViewController: UIViewController {
    private let urls: [URL]
    private let headers: [String: String]
    private let startIndex: Int
    private var didScrollToStart = false

    private let collectionView: UICollectionView
    private let closeButton = UIButton(type: .system)
    private let indexLabel = UILabel()

    init(urls: [URL], startIndex: Int, headers: [String: String]) {
        self.urls = urls
        self.startIndex = max(0, min(startIndex, urls.count - 1))
        self.headers = headers
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ChatImagePreviewCell.self, forCellWithReuseIdentifier: ChatImagePreviewCell.reuseID)

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .gray30
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        indexLabel.font = .pretendard(.medium, size: 12)
        indexLabel.textColor = .gray60
        indexLabel.textAlignment = .center

        view.addSubview(collectionView)
        view.addSubview(closeButton)
        view.addSubview(indexLabel)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-12)
            make.width.height.equalTo(32)
        }

        indexLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(closeButton)
        }

        updateIndexLabel(for: startIndex)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard didScrollToStart == false else { return }
        let indexPath = IndexPath(item: startIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        didScrollToStart = true
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func updateIndexLabel(for index: Int) {
        indexLabel.text = "\(index + 1) / \(urls.count)"
    }
}

extension ChatRoomImagePreviewViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        urls.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ChatImagePreviewCell.reuseID,
            for: indexPath
        ) as? ChatImagePreviewCell else {
            return UICollectionViewCell()
        }
        cell.configure(url: urls[indexPath.item], headers: headers)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateIndexLabelForScroll()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateIndexLabelForScroll()
    }

    private func updateIndexLabelForScroll() {
        let pageWidth = max(collectionView.bounds.width, 1)
        let index = Int(round(collectionView.contentOffset.x / pageWidth))
        updateIndexLabel(for: max(0, min(index, urls.count - 1)))
    }
}

private final class ChatImagePreviewCell: UICollectionViewCell {
    static let reuseID = "ChatImagePreviewCell"

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .black

        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    func configure(url: URL, headers: [String: String]) {
        KingfisherHelper.setImage(
            imageView,
            url: url,
            headers: headers,
            placeholder: nil,
            logLabel: "chat-preview"
        )
    }
}
