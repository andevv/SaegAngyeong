//
//  FilterDetailViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/24/25.
//

import UIKit
import SnapKit
import Combine
import MapKit

final class FilterDetailViewController: BaseViewController<FilterDetailViewModel> {
    private let navTitleView = MarqueeTitleView()
    private let orderRepository: OrderRepository
    private let paymentRepository: PaymentRepository
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let compareContainerView = UIView()
    private let compareView = FilterCompareView()
    private let compareBar = UIView()
    private let afterLabel = UILabel()
    private let beforeLabel = UILabel()
    private let compareThumb = UIView()

    private let priceLabel = UILabel()
    private let coinLabel = UILabel()

    private let statsStack = UIStackView()
    private let downloadCard = StatCardView()
    private let likeCard = StatCardView()

    private let metadataCard = MetadataCardView()
    private let presetsCard = PresetsCardView()
    private let dividerView = UIView()
    private let authorProfileImageView = UIImageView()
    private let authorNameLabel = UILabel()
    private let authorNickLabel = UILabel()
    private let messageButton = UIButton(type: .system)
    private let tagStackView = UIStackView()
    private let filterDescriptionLabel = UILabel()
    private let purchaseButton = UIButton(type: .system)

    private let likeButton = UIButton(type: .system)

    private var compareProgress: CGFloat = 0.5
    private var currentViewData: FilterDetailViewData?

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let likeToggleSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()

    init(
        viewModel: FilterDetailViewModel,
        orderRepository: OrderRepository,
        paymentRepository: PaymentRepository
    ) {
        self.orderRepository = orderRepository
        self.paymentRepository = paymentRepository
        super.init(viewModel: viewModel)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let maxWidth = max(140, view.bounds.width - 160)
        navTitleView.bounds.size = CGSize(width: maxWidth, height: 24)
        navTitleView.setNeedsLayout()
        navTitleView.layoutIfNeeded()
    }

    override func configureUI() {
        navTitleView.textColor = .gray60
        navTitleView.font = .mulgyeol(.bold, size: 20)
        navigationItem.titleView = navTitleView

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        compareContainerView.backgroundColor = .blackTurquoise
        compareContainerView.layer.cornerRadius = 16
        compareContainerView.clipsToBounds = true

        afterLabel.text = "After"
        afterLabel.textColor = .gray60
        afterLabel.font = .pretendard(.medium, size: 12)

        beforeLabel.text = "Before"
        beforeLabel.textColor = .gray60
        beforeLabel.font = .pretendard(.medium, size: 12)

        compareBar.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        compareBar.layer.cornerRadius = 12

        compareThumb.backgroundColor = .gray90
        compareThumb.layer.cornerRadius = 16
        compareThumb.layer.borderWidth = 1
        compareThumb.layer.borderColor = UIColor.gray75.cgColor

        priceLabel.font = .mulgyeol(.bold, size: 28)
        priceLabel.textColor = .gray30

        coinLabel.font = .pretendard(.bold, size: 18)
        coinLabel.textColor = .gray60

        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually

        downloadCard.configure(title: "다운로드", value: "-")
        likeCard.configure(title: "찜하기", value: "-")

        dividerView.backgroundColor = UIColor.white.withAlphaComponent(0.08)

        authorProfileImageView.contentMode = .scaleAspectFill
        authorProfileImageView.clipsToBounds = true
        authorProfileImageView.layer.cornerRadius = 24
        authorProfileImageView.layer.borderWidth = 1
        authorProfileImageView.layer.borderColor = UIColor.gray90.withAlphaComponent(0.3).cgColor

        authorNameLabel.font = .mulgyeol(.bold, size: 18)
        authorNameLabel.textColor = .gray30

        authorNickLabel.font = .pretendard(.medium, size: 12)
        authorNickLabel.textColor = .gray75

        messageButton.setImage(UIImage(named: "Icon_Message"), for: .normal)
        messageButton.tintColor = .gray60
        messageButton.backgroundColor = .blackTurquoise
        messageButton.layer.cornerRadius = 12
        messageButton.clipsToBounds = true
        messageButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        messageButton.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)

        tagStackView.axis = .horizontal
        tagStackView.spacing = 8
        tagStackView.alignment = .leading

        filterDescriptionLabel.font = .pretendard(.regular, size: 12)
        filterDescriptionLabel.textColor = .gray60
        filterDescriptionLabel.numberOfLines = 0

        likeButton.setImage(UIImage(named: "Icon_Like_Empty"), for: .normal)
        likeButton.tintColor = .gray60
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        purchaseButton.setTitle("결제하기", for: .normal)
        purchaseButton.titleLabel?.font = .pretendard(.bold, size: 16)
        purchaseButton.backgroundColor = UIColor.brightTurquoise.withAlphaComponent(0.9)
        purchaseButton.setTitleColor(.gray30, for: .normal)
        purchaseButton.layer.cornerRadius = 12
        purchaseButton.addTarget(self, action: #selector(purchaseTapped), for: .touchUpInside)

        [
            compareContainerView,
            compareBar,
            afterLabel,
            beforeLabel,
            priceLabel,
            coinLabel,
            statsStack,
            metadataCard,
            presetsCard,
            dividerView,
            authorProfileImageView,
            authorNameLabel,
            authorNickLabel,
            messageButton,
            tagStackView,
            filterDescriptionLabel,
            purchaseButton
        ].forEach { contentView.addSubview($0) }

        compareContainerView.addSubview(compareView)
        compareBar.addSubview(compareThumb)
        statsStack.addArrangedSubview(downloadCard)
        statsStack.addArrangedSubview(likeCard)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: likeButton)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleComparePan(_:)))
        compareBar.addGestureRecognizer(pan)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        compareContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(compareContainerView.snp.width).multipliedBy(1.05)
        }

        compareView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        compareBar.snp.makeConstraints { make in
            make.top.equalTo(compareContainerView.snp.bottom).offset(12)
            make.leading.trailing.equalTo(compareContainerView)
            make.height.equalTo(32)
        }

        compareThumb.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(32)
        }

        afterLabel.snp.makeConstraints { make in
            make.centerY.equalTo(compareBar)
            make.leading.equalTo(compareBar.snp.leading).offset(12)
        }

        beforeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(compareBar)
            make.trailing.equalTo(compareBar.snp.trailing).inset(12)
        }

        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(compareBar.snp.bottom).offset(24)
            make.leading.equalTo(compareContainerView)
        }

        coinLabel.snp.makeConstraints { make in
            make.bottom.equalTo(priceLabel.snp.bottom).offset(-4)
            make.leading.equalTo(priceLabel.snp.trailing).offset(8)
        }

        statsStack.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(16)
            make.leading.trailing.equalTo(compareContainerView)
            make.height.equalTo(70)
        }

        metadataCard.snp.makeConstraints { make in
            make.top.equalTo(statsStack.snp.bottom).offset(16)
            make.leading.trailing.equalTo(compareContainerView)
        }

        presetsCard.snp.makeConstraints { make in
            make.top.equalTo(metadataCard.snp.bottom).offset(16)
            make.leading.trailing.equalTo(compareContainerView)
        }

        purchaseButton.snp.makeConstraints { make in
            make.top.equalTo(presetsCard.snp.bottom).offset(16)
            make.leading.trailing.equalTo(compareContainerView)
            make.height.equalTo(48)
        }

        dividerView.snp.makeConstraints { make in
            make.top.equalTo(purchaseButton.snp.bottom).offset(20)
            make.leading.trailing.equalTo(compareContainerView)
            make.height.equalTo(1)
        }

        authorProfileImageView.snp.makeConstraints { make in
            make.top.equalTo(dividerView.snp.bottom).offset(16)
            make.leading.equalTo(compareContainerView)
            make.width.height.equalTo(48)
        }

        authorNameLabel.snp.makeConstraints { make in
            make.top.equalTo(authorProfileImageView.snp.top).offset(2)
            make.leading.equalTo(authorProfileImageView.snp.trailing).offset(12)
        }

        authorNickLabel.snp.makeConstraints { make in
            make.top.equalTo(authorNameLabel.snp.bottom).offset(4)
            make.leading.equalTo(authorNameLabel)
        }

        messageButton.snp.makeConstraints { make in
            make.centerY.equalTo(authorProfileImageView)
            make.trailing.equalTo(compareContainerView)
            make.width.height.equalTo(44)
        }

        tagStackView.snp.makeConstraints { make in
            make.top.equalTo(authorProfileImageView.snp.bottom).offset(12)
            make.leading.equalTo(compareContainerView)
            make.trailing.lessThanOrEqualTo(compareContainerView)
        }

        filterDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(tagStackView.snp.bottom).offset(12)
            make.leading.trailing.equalTo(compareContainerView)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    override func bindViewModel() {
        let input = FilterDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            likeToggle: likeToggleSubject.eraseToAnyPublisher(),
            refresh: refreshSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.detail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewData in
                self?.apply(viewData)
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func apply(_ viewData: FilterDetailViewData) {
        currentViewData = viewData
        navTitleView.setText(viewData.title)
        priceLabel.text = "\(viewData.price)"
        coinLabel.text = "Coin"
        compareView.setImages(original: viewData.originalImageURL, filtered: viewData.filteredImageURL, headers: viewData.headers)
        compareView.setProgress(compareProgress)
        downloadCard.configure(title: "다운로드", value: "\(viewData.buyerCount)+")
        likeCard.configure(title: "찜하기", value: "\(viewData.likeCount)")
        let likeIcon = viewData.isLiked ? "Icon_Like_Fill" : "Icon_Like_Empty"
        likeButton.setImage(UIImage(named: likeIcon), for: .normal)
        metadataCard.configure(
            title: viewData.metadataTitle,
            line1: viewData.metadataLine1,
            line2: viewData.metadataLine2,
            line3: viewData.metadataLine3,
            format: viewData.metadataFormat,
            latitude: viewData.latitude,
            longitude: viewData.longitude
        )
        presetsCard.configure(items: viewData.presets, locked: viewData.requiresPurchase && !viewData.isPurchased)
        purchaseButton.isHidden = !viewData.requiresPurchase
        if viewData.requiresPurchase {
            if viewData.isPurchased {
                purchaseButton.setTitle("구매완료", for: .normal)
                purchaseButton.backgroundColor = UIColor.gray90.withAlphaComponent(0.9)
                purchaseButton.setTitleColor(.gray75, for: .normal)
                purchaseButton.isEnabled = false
            } else {
                purchaseButton.setTitle("결제하기", for: .normal)
                purchaseButton.backgroundColor = UIColor.brightTurquoise.withAlphaComponent(0.9)
                purchaseButton.setTitleColor(.gray30, for: .normal)
                purchaseButton.isEnabled = true
            }
        }

        authorNameLabel.text = viewData.creatorName
        authorNickLabel.text = viewData.creatorNick
        filterDescriptionLabel.text = viewData.description
        tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        viewData.creatorHashTags.forEach { tag in
            let label = PaddingLabel(padding: UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10))
            label.text = tag.hasPrefix("#") ? tag : "#\(tag)"
            label.font = .pretendard(.medium, size: 11)
            label.textColor = .gray60
            label.backgroundColor = .blackTurquoise
            label.layer.cornerRadius = 10
            label.clipsToBounds = true
            tagStackView.addArrangedSubview(label)
        }
        KingfisherHelper.setImage(authorProfileImageView, url: viewData.creatorProfileURL, headers: viewData.headers, logLabel: "creator-profile")
    }

    @objc private func handleComparePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: compareBar)
        let width = compareBar.bounds.width
        var centerX = compareThumb.center.x + translation.x
        centerX = max(16, min(width - 16, centerX))
        compareThumb.center.x = centerX
        gesture.setTranslation(.zero, in: compareBar)
        let progress = (centerX - 16) / (width - 32)
        compareProgress = progress
        compareView.setProgress(progress)
    }

    @objc private func likeTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        likeToggleSubject.send(())
    }

    @objc private func messageTapped() {
        print("[FilterDetail] message tapped")
    }

    @objc private func purchaseTapped() {
        guard let viewData = currentViewData, viewData.requiresPurchase, !viewData.isPurchased else { return }
        let paymentViewModel = PaymentViewModel(
            filterID: viewData.filterID,
            title: viewData.title,
            totalPrice: viewData.price,
            orderRepository: orderRepository,
            paymentRepository: paymentRepository
        )
        let paymentViewController = PaymentViewController(viewModel: paymentViewModel)
        paymentViewController.onPaymentSuccess = { [weak self] in
            self?.refreshSubject.send(())
        }
        navigationController?.pushViewController(paymentViewController, animated: true)
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

private final class StatCardView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .blackTurquoise
        layer.cornerRadius = 12

        titleLabel.font = .pretendard(.medium, size: 12)
        titleLabel.textColor = .gray60

        valueLabel.font = .pretendard(.bold, size: 18)
        valueLabel.textColor = .gray30

        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

private final class MarqueeTitleView: UIView {
    private let contentView = UIView()
    private let label = UILabel()
    private let trailingLabel = UILabel()
    private let spacing: CGFloat = 36

    var font: UIFont? {
        get { label.font }
        set {
            label.font = newValue
            trailingLabel.font = newValue
        }
    }

    var textColor: UIColor? {
        get { label.textColor }
        set {
            label.textColor = newValue
            trailingLabel.textColor = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubview(contentView)
        contentView.addSubview(label)
        contentView.addSubview(trailingLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String) {
        label.text = text
        trailingLabel.text = text
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let labelSize = label.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: bounds.height))
        let y = (bounds.height - labelSize.height) / 2
        label.frame = CGRect(x: 0, y: y, width: labelSize.width, height: labelSize.height)
        trailingLabel.frame = CGRect(x: label.frame.maxX + spacing, y: y, width: labelSize.width, height: labelSize.height)
        contentView.frame = CGRect(x: 0, y: 0, width: trailingLabel.frame.maxX, height: bounds.height)
        updateAnimationIfNeeded(labelSize: labelSize, y: y)
    }

    private func updateAnimationIfNeeded(labelSize: CGSize, y: CGFloat) {
        let overflow = label.bounds.width - bounds.width
        contentView.layer.removeAllAnimations()
        contentView.transform = .identity
        guard overflow > 8 else {
            trailingLabel.isHidden = true
            contentView.frame = bounds
            let centeredX = max(0, (bounds.width - labelSize.width) / 2)
            label.frame = CGRect(x: centeredX, y: y, width: labelSize.width, height: labelSize.height)
            return
        }
        trailingLabel.isHidden = false
        let distance = label.bounds.width + spacing
        let duration = Double(distance / 30)
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = 0
        animation.toValue = -distance
        animation.duration = max(3, duration)
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.repeatCount = .infinity
        contentView.layer.add(animation, forKey: "marquee")
    }
}

private final class MetadataCardView: UIView {
    private let headerBackground = UIView()
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let formatLabel = UILabel()
    private let mapView = MKMapView()
    private let noLocationView = UIView()
    private let noLocationImageView = UIImageView()
    private let noLocationLabel = UILabel()
    private let infoStack = UIStackView()
    private let line1Label = UILabel()
    private let line2Label = UILabel()
    private let line3Label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .blackTurquoise
        layer.cornerRadius = 12

        headerBackground.backgroundColor = .black
        headerBackground.layer.borderWidth = 3
        headerBackground.layer.borderColor = UIColor.blackTurquoise.cgColor
        headerBackground.layer.cornerRadius = 12
        headerBackground.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        addSubview(headerBackground)

        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing
        headerBackground.addSubview(headerStack)

        titleLabel.font = .pretendard(.bold, size: 14)
        titleLabel.textColor = .deepTurquoise
        formatLabel.font = .pretendard(.bold, size: 12)
        formatLabel.textColor = .deepTurquoise
        formatLabel.text = "EXIF"

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(formatLabel)

        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        addSubview(mapView)

        noLocationView.backgroundColor = .blackTurquoise
        noLocationView.layer.cornerRadius = 12
        noLocationView.layer.borderWidth = 2
        noLocationView.layer.borderColor = UIColor.deepTurquoise.cgColor
        noLocationView.isHidden = true
        addSubview(noLocationView)

        noLocationImageView.image = UIImage(named: "Icon_NoLocation")
        noLocationImageView.tintColor = .deepTurquoise
        noLocationImageView.contentMode = .scaleAspectFit

        noLocationLabel.text = "No Location"
        noLocationLabel.font = .pretendard(.medium, size: 10)
        noLocationLabel.textColor = .deepTurquoise

        noLocationView.addSubview(noLocationImageView)
        noLocationView.addSubview(noLocationLabel)

        infoStack.axis = .vertical
        infoStack.spacing = 6
        addSubview(infoStack)

        line1Label.font = .pretendard(.medium, size: 12)
        line1Label.textColor = .gray75

        line2Label.font = .pretendard(.medium, size: 12)
        line2Label.textColor = .gray75

        line3Label.font = .pretendard(.regular, size: 11)
        line3Label.textColor = .gray75

        [line1Label, line2Label, line3Label].forEach { infoStack.addArrangedSubview($0) }

        headerBackground.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }

        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(headerBackground.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(72)
            make.bottom.equalToSuperview().inset(12)
        }

        noLocationView.snp.makeConstraints { make in
            make.edges.equalTo(mapView)
        }

        noLocationImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(26)
        }

        noLocationLabel.snp.makeConstraints { make in
            make.top.equalTo(noLocationImageView.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }

        infoStack.snp.makeConstraints { make in
            make.leading.equalTo(mapView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(mapView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, line1: String, line2: String, line3: String, format: String, latitude: Double?, longitude: Double?) {
        titleLabel.text = title
        line1Label.text = line1
        line2Label.text = line2
        line3Label.text = line3
        line3Label.isHidden = line3.isEmpty
        formatLabel.text = format

        if let lat = latitude, let lon = longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 250, longitudinalMeters: 250)
            mapView.setRegion(region, animated: false)
            mapView.removeAnnotations(mapView.annotations)
            mapView.isHidden = false
            noLocationView.isHidden = true
            line3Label.isHidden = line3.isEmpty
        } else {
            mapView.isHidden = true
            noLocationView.isHidden = false
            line3Label.isHidden = true
        }
    }
}

private final class PresetsCardView: UIView {
    private let headerBackground = UIView()
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let lutLabel = UILabel()
    private let gridStack = UIStackView()
    private let overlayView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let lockIcon = UIImageView()
    private let lockLabel = UILabel()

    private var itemViews: [PresetItemView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .blackTurquoise
        layer.cornerRadius = 12

        headerBackground.backgroundColor = .black
        headerBackground.layer.borderWidth = 3
        headerBackground.layer.borderColor = UIColor.blackTurquoise.cgColor
        headerBackground.layer.cornerRadius = 12
        headerBackground.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        addSubview(headerBackground)

        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing
        headerBackground.addSubview(headerStack)

        titleLabel.text = "Filter Presets"
        titleLabel.font = .pretendard(.bold, size: 14)
        titleLabel.textColor = .deepTurquoise

        lutLabel.text = "LUT"
        lutLabel.font = .pretendard(.bold, size: 12)
        lutLabel.textColor = .deepTurquoise

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(lutLabel)

        gridStack.axis = .vertical
        gridStack.spacing = 14
        addSubview(gridStack)

        overlayView.isOpaque = false
        overlayView.alpha = 1.0
        overlayView.layer.cornerRadius = 12
        overlayView.clipsToBounds = true
        overlayView.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        addSubview(overlayView)

        lockIcon.image = UIImage(named: "Icon_Lock")
        lockIcon.tintColor = .gray30
        overlayView.contentView.addSubview(lockIcon)

        lockLabel.text = "결제가 필요한 유료 필터입니다"
        lockLabel.font = .pretendard(.bold, size: 14)
        lockLabel.textColor = .gray30
        overlayView.contentView.addSubview(lockLabel)

        headerBackground.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }

        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        gridStack.snp.makeConstraints { make in
            make.top.equalTo(headerBackground.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(16)
        }

        overlayView.snp.makeConstraints { make in
            make.edges.equalTo(gridStack)
        }

        lockIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-14)
            make.width.height.equalTo(28)
        }

        lockLabel.snp.makeConstraints { make in
            make.top.equalTo(lockIcon.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }

        configure(items: [], locked: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [FilterPresetViewData], locked: Bool) {
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()

        let rows = stride(from: 0, to: items.count, by: 6).map { idx in
            Array(items[idx..<min(idx + 6, items.count)])
        }
        rows.forEach { rowItems in
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 14
            rowStack.distribution = .fillEqually
            rowItems.forEach { item in
                let view = PresetItemView()
                view.configure(iconName: item.iconName, valueText: item.valueText)
                rowStack.addArrangedSubview(view)
                itemViews.append(view)
            }
            gridStack.addArrangedSubview(rowStack)
        }

        overlayView.isHidden = !locked
        gridStack.alpha = 1.0
    }
}

private final class PresetItemView: UIView {
    private let iconView = UIImageView()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .gray30
        addSubview(iconView)

        valueLabel.font = .pretendard(.medium, size: 11)
        valueLabel.textColor = .gray60
        valueLabel.textAlignment = .center
        addSubview(valueLabel)

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(28)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(iconName: String, valueText: String) {
        if let image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate) {
            iconView.image = image
        } else {
            iconView.image = UIImage(named: iconName)
        }
        valueLabel.text = valueText
    }
}
