//
//  ChatRoomImagePreviewViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/12/26.
//

import UIKit
import SnapKit
import Photos

final class ChatRoomImagePreviewViewController: UIViewController {
    private let urls: [URL]
    private let headers: [String: String]
    private let startIndex: Int
    private var didScrollToStart = false

    private let collectionView: UICollectionView
    private let closeButton = UIButton(type: .system)
    private let indexLabel = UILabel()
    private let downloadButton = UIButton(type: .system)

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

        downloadButton.setImage(UIImage(systemName: "arrow.down.to.line"), for: .normal)
        downloadButton.tintColor = .gray30
        downloadButton.backgroundColor = .clear
        downloadButton.layer.cornerRadius = 0
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)

        indexLabel.font = .pretendard(.medium, size: 12)
        indexLabel.textColor = .gray60
        indexLabel.textAlignment = .center

        view.addSubview(collectionView)
        view.addSubview(closeButton)
        view.addSubview(downloadButton)
        view.addSubview(indexLabel)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-12)
            make.width.height.equalTo(32)
        }

        downloadButton.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(12)
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

    @objc private func downloadTapped() {
        let index = currentIndex()
        guard urls.indices.contains(index) else { return }
        requestPhotoAuthorization { [weak self] isAuthorized in
            guard let self, isAuthorized else {
                self?.presentAlert(title: "권한 필요", message: "사진 저장 권한을 허용해주세요.")
                return
            }
            self.downloadImage(url: self.urls[index])
        }
    }

    private func updateIndexLabel(for index: Int) {
        indexLabel.text = "\(index + 1) / \(urls.count)"
    }

    private func requestPhotoAuthorization(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        default:
            completion(false)
        }
    }

    private func downloadImage(url: URL) {
        setDownloadLoading(true)
        var request = URLRequest(url: url)
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            if let data {
                self.saveToPhotoLibrary(data: data, fallbackFileName: response?.suggestedFilename)
            } else {
                DispatchQueue.main.async {
                    self.setDownloadLoading(false)
                    self.presentAlert(title: "다운로드 실패", message: error?.localizedDescription ?? "이미지를 불러올 수 없습니다.")
                }
            }
        }.resume()
    }

    private func saveToPhotoLibrary(data: Data, fallbackFileName: String?) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            if let name = fallbackFileName {
                options.originalFilename = name
            }
            request.addResource(with: .photo, data: data, options: options)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.setDownloadLoading(false)
                if success {
                    self?.presentAlert(title: "저장 완료", message: "사진 앱에 저장되었습니다.")
                } else {
                    self?.presentAlert(title: "저장 실패", message: error?.localizedDescription ?? "저장 중 오류가 발생했습니다.")
                }
            }
        }
    }

    private func setDownloadLoading(_ isLoading: Bool) {
        downloadButton.isEnabled = !isLoading
        downloadButton.alpha = isLoading ? 0.5 : 1.0
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
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
        cell.onZoomChanged = { [weak self] isZoomed in
            guard let self else { return }
            if self.currentIndex() == indexPath.item {
                self.collectionView.isScrollEnabled = !isZoomed
            }
        }
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

    private func currentIndex() -> Int {
        let pageWidth = max(collectionView.bounds.width, 1)
        return Int(round(collectionView.contentOffset.x / pageWidth))
    }
}

private final class ChatImagePreviewCell: UICollectionViewCell {
    static let reuseID = "ChatImagePreviewCell"

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    var onZoomChanged: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        scrollView.backgroundColor = .black
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.bouncesZoom = false

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .black

        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalToSuperview()
        }

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        scrollView.setZoomScale(1.0, animated: false)
        scrollView.contentInset = .zero
        onZoomChanged?(false)
        onZoomChanged = nil
    }

    func configure(url: URL, headers: [String: String]) {
        scrollView.setZoomScale(1.0, animated: false)
        scrollView.contentInset = .zero
        KingfisherHelper.setImage(
            imageView,
            url: url,
            headers: headers,
            placeholder: nil,
            logLabel: "chat-preview"
        )
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let targetScale: CGFloat = scrollView.zoomScale > 1.0 ? 1.0 : 2.5
        if targetScale == 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
            return
        }
        let location = gesture.location(in: imageView)
        let zoomRect = zoomRect(for: targetScale, center: location)
        scrollView.zoom(to: zoomRect, animated: true)
    }

    private func zoomRect(for scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(
            width: scrollView.bounds.width / scale,
            height: scrollView.bounds.height / scale
        )
        let origin = CGPoint(
            x: center.x - size.width / 2.0,
            y: center.y - size.height / 2.0
        )
        return CGRect(origin: origin, size: size)
    }
}

extension ChatImagePreviewCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.contentInset = .zero
        clampContentOffset()
        onZoomChanged?(scrollView.zoomScale > 1.0)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollView.contentInset = .zero
        clampContentOffset()
        onZoomChanged?(scale > 1.0)
    }

    private func clampContentOffset() {
        let maxOffsetX = max(0, scrollView.contentSize.width - scrollView.bounds.width)
        let maxOffsetY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        var offset = scrollView.contentOffset
        offset.x = min(max(0, offset.x), maxOffsetX)
        offset.y = min(max(0, offset.y), maxOffsetY)
        if offset != scrollView.contentOffset {
            scrollView.setContentOffset(offset, animated: false)
        }
    }
}
