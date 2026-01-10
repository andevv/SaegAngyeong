//
//  FilterMakeViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/29/25.
//

import UIKit
import SnapKit
import Combine
import PhotosUI
import ImageIO
import UniformTypeIdentifiers
import CoreLocation

final class FilterMakeViewController: BaseViewController<FilterMakeViewModel> {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private lazy var keyboardObserver = KeyboardInsetObserver(scrollView: scrollView, containerView: view)

    private let nameLabel = UILabel()
    private let nameFieldContainer = UIView()
    private let nameTextField = UITextField()

    private let categoryLabel = UILabel()
    private let categoryStackView = UIStackView()
    private var categoryButtons: [FilterMakeCategory: UIButton] = [:]

    private let photoLabel = UILabel()
    private let photoContainerView = UIView()
    private let photoImageView = UIImageView()
    private let photoAddIconView = UIImageView()
    private let photoTapButton = UIButton(type: .system)
    private let editButton = UIButton(type: .system)
    private var photoHeightConstraint: Constraint?
    private var isPhotoSquare = false
    private let metadataCard = MetadataCardView()
    private var metadataCardHeightConstraint: Constraint?
    private let geocoder = CLGeocoder()
    private var metadataLine3: String = ""
    private var currentMetadata: PhotoMetadata?

    private let descriptionLabel = UILabel()
    private let descriptionContainer = UIView()
    private let descriptionTextView = UITextView()
    private let descriptionPlaceholderLabel = UILabel()

    private let priceLabel = UILabel()
    private let priceContainer = UIView()
    private let priceTextField = UITextField()
    private let priceUnitLabel = UILabel()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let titleChangedSubject = PassthroughSubject<String, Never>()
    private let categorySelectedSubject = PassthroughSubject<FilterMakeCategory, Never>()
    private let descriptionChangedSubject = PassthroughSubject<String, Never>()
    private let priceChangedSubject = PassthroughSubject<String, Never>()
    private let imageSelectedSubject = PassthroughSubject<UIImage?, Never>()
    private let metadataSelectedSubject = PassthroughSubject<PhotoMetadata?, Never>()
    private let saveTappedSubject = PassthroughSubject<Void, Never>()

    private let saveButton = UIButton(type: .system)
    private var isSaveEnabled = false
    private var isSaving = false
    private var selectedCategory: FilterMakeCategory?
    private var currentAdjustments = FilterAdjustmentValues.defaultValues

    override init(viewModel: FilterMakeViewModel) {
        super.init(viewModel: viewModel)
        tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "Filter_Empty"),
            selectedImage: UIImage(named: "Filter_Fill")
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePhotoHeight()
    }

    override func configureUI() {
        let navTitleLabel = UILabel()
        navTitleLabel.text = "MAKE"
        navTitleLabel.textColor = .gray60
        navTitleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = navTitleLabel

        saveButton.setImage(UIImage(named: "Icon_Save"), for: .normal)
        saveButton.tintColor = .gray60
        saveButton.isEnabled = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)

        nameLabel.text = "필터명"
        nameLabel.textColor = .gray60
        nameLabel.font = .pretendard(.medium, size: 16)

        styleFieldContainer(nameFieldContainer)
        nameTextField.textColor = .gray60
        nameTextField.font = .pretendard(.regular, size: 14)
        nameTextField.attributedPlaceholder = NSAttributedString(
            string: "필터 이름을 입력해주세요.",
            attributes: [.foregroundColor: UIColor.gray75]
        )
        nameTextField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)

        categoryLabel.text = "카테고리"
        categoryLabel.textColor = .gray60
        categoryLabel.font = .pretendard(.medium, size: 16)

        categoryStackView.axis = .horizontal
        categoryStackView.spacing = 8
        categoryStackView.alignment = .leading
        categoryStackView.distribution = .fillEqually

        FilterMakeCategory.allCases.forEach { category in
            let button = makeCategoryButton(title: category.title)
            button.tag = categoryButtonTag(for: category)
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            categoryButtons[category] = button
            categoryStackView.addArrangedSubview(button)
        }

        photoLabel.text = "대표 사진 등록"
        photoLabel.textColor = .gray60
        photoLabel.font = .pretendard(.medium, size: 16)

        photoContainerView.backgroundColor = .blackTurquoise
        photoContainerView.layer.cornerRadius = 12
        photoContainerView.clipsToBounds = true

        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true

        photoAddIconView.image = UIImage(named: "Icon_Add")
        photoAddIconView.tintColor = .gray60
        photoAddIconView.contentMode = .scaleAspectFit

        photoTapButton.backgroundColor = .clear
        photoTapButton.addTarget(self, action: #selector(photoTapped), for: .touchUpInside)

        editButton.setTitle("수정하기", for: .normal)
        editButton.setTitleColor(.gray75, for: .normal)
        editButton.titleLabel?.font = .pretendard(.medium, size: 16)
        editButton.isHidden = true
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

        descriptionLabel.text = "필터 소개"
        descriptionLabel.textColor = .gray60
        descriptionLabel.font = .pretendard(.medium, size: 16)

        styleFieldContainer(descriptionContainer)
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.textColor = .gray30
        descriptionTextView.font = .pretendard(.regular, size: 14)
        descriptionTextView.delegate = self
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        descriptionPlaceholderLabel.text = "이 필터에 대한 간단한 소개를 작성해주세요."
        descriptionPlaceholderLabel.textColor = .gray75
        descriptionPlaceholderLabel.font = .pretendard(.regular, size: 14)

        priceLabel.text = "판매 가격"
        priceLabel.textColor = .gray60
        priceLabel.font = .pretendard(.medium, size: 16)

        styleFieldContainer(priceContainer)
        priceTextField.textColor = .gray30
        priceTextField.font = .pretendard(.regular, size: 14)
        priceTextField.attributedPlaceholder = NSAttributedString(
            string: "1,000",
            attributes: [.foregroundColor: UIColor.gray75]
        )
        priceTextField.keyboardType = .numberPad
        priceTextField.delegate = self
        priceTextField.addTarget(self, action: #selector(priceChanged), for: .editingChanged)

        priceUnitLabel.text = "원"
        priceUnitLabel.textColor = .gray60
        priceUnitLabel.font = .pretendard(.regular, size: 14)

        [
            nameLabel,
            nameFieldContainer,
            categoryLabel,
            categoryStackView,
            photoLabel,
            photoContainerView,
            metadataCard,
            descriptionLabel,
            descriptionContainer,
            priceLabel,
            priceContainer
        ].forEach { contentView.addSubview($0) }

        nameFieldContainer.addSubview(nameTextField)
        photoContainerView.addSubview(photoImageView)
        photoContainerView.addSubview(photoAddIconView)
        photoContainerView.addSubview(photoTapButton)
        contentView.addSubview(editButton)
        descriptionContainer.addSubview(descriptionTextView)
        descriptionContainer.addSubview(descriptionPlaceholderLabel)
        priceContainer.addSubview(priceTextField)
        priceContainer.addSubview(priceUnitLabel)

        metadataCard.isHidden = true
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        nameFieldContainer.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        nameTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(nameFieldContainer.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        categoryStackView.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(32)
        }

        photoLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryStackView.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        photoContainerView.snp.makeConstraints { make in
            make.top.equalTo(photoLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            photoHeightConstraint = make.height.equalTo(90).constraint
        }

        photoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        photoAddIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        editButton.snp.makeConstraints { make in
            make.centerY.equalTo(photoLabel)
            make.trailing.equalToSuperview().inset(20)
        }

        photoTapButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        metadataCard.snp.makeConstraints { make in
            make.top.equalTo(photoContainerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            metadataCardHeightConstraint = make.height.equalTo(0).constraint
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(metadataCard.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        descriptionContainer.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(90)
        }

        descriptionTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        descriptionPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(12)
        }

        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionContainer.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(20)
        }

        priceContainer.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-24)
        }

        priceTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalTo(priceUnitLabel.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        priceUnitLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
    }

    override func bindViewModel() {
        let input = FilterMakeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            titleChanged: titleChangedSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            descriptionChanged: descriptionChangedSubject.eraseToAnyPublisher(),
            priceChanged: priceChangedSubject.eraseToAnyPublisher(),
            imageSelected: imageSelectedSubject.eraseToAnyPublisher(),
            metadataSelected: metadataSelectedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.selectedCategory
            .sink { [weak self] category in
                self?.applySelectedCategory(category)
                self?.selectedCategory = category
            }
            .store(in: &cancellables)

        output.previewImage
            .sink { [weak self] image in
                self?.updatePhoto(image: image)
            }
            .store(in: &cancellables)

        output.isSaveEnabled
            .sink { [weak self] enabled in
                self?.isSaveEnabled = enabled
                self?.updateSaveButtonState()
            }
            .store(in: &cancellables)

        output.isSaving
            .sink { [weak self] saving in
                self?.isSaving = saving
                self?.updateSaveButtonState()
            }
            .store(in: &cancellables)

        output.createdFilter
            .sink { [weak self] filter in
                self?.presentCreateSuccess(title: filter.title)
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func styleFieldContainer(_ view: UIView) {
        view.backgroundColor = .blackTurquoise
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.gray90.withAlphaComponent(0.3).cgColor
    }

    private func makeCategoryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .pretendard(.medium, size: 11)
        button.setTitleColor(.gray60, for: .normal)
        button.backgroundColor = .gray15.withAlphaComponent(0.15)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray90.withAlphaComponent(0.25).cgColor
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return button
    }

    private func applySelectedCategory(_ category: FilterMakeCategory?) {
        categoryButtons.forEach { entry in
            let isSelected = entry.key == category
            let button = entry.value
            button.setTitleColor(isSelected ? .gray30 : .gray60, for: .normal)
            button.backgroundColor = isSelected ? UIColor.brightTurquoise.withAlphaComponent(0.4) : .gray15.withAlphaComponent(0.15)
            button.layer.borderColor = (isSelected ? UIColor.brightTurquoise : UIColor.gray90.withAlphaComponent(0.25)).cgColor
        }
    }

    private func updatePhoto(image: UIImage?) {
        photoImageView.image = image
        photoAddIconView.isHidden = image != nil
        editButton.isHidden = image == nil
        isPhotoSquare = image != nil
        updatePhotoHeight()
    }

    private func updateMetadataCard(with metadata: PhotoMetadata?) {
        guard let metadata else {
            metadataCard.isHidden = true
            metadataCardHeightConstraint?.update(offset: 0)
            return
        }

        let title = metadata.camera ?? "촬영 정보"
        let line1: String = {
            var parts: [String] = []
            if let lens = mappedLensInfo(from: metadata) {
                parts.append("\(lens) -")
            }
            if let focal = metadata.focalLength {
                let focalText = focal.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(focal))" : String(format: "%.1f", focal)
                parts.append("\(focalText)mm")
            }
            if let aperture = metadata.aperture {
                let fText = aperture.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(aperture))" : String(format: "%.1f", aperture)
                parts.append("𝒇\(fText)")
            }
            if let iso = metadata.iso {
                parts.append("ISO \(iso)")
            }
            return parts.joined(separator: " ")
        }()

        let line2: String = {
            let resolution: String? = {
                guard let width = metadata.pixelWidth,
                      let height = metadata.pixelHeight else { return nil }
                let mp = Double(width * height) / 1_000_000.0
                let mpText = String(format: "%.0fMP", mp)
                return "\(mpText) · \(width) × \(height)"
            }()
            let fileSizeText: String? = {
                guard let bytes = metadata.fileSize else { return nil }
                let mb = bytes / 1_000_000.0
                return String(format: "%.1fMB", mb)
            }()
            return [resolution, fileSizeText].compactMap { $0 }.joined(separator: " · ")
        }()

        let format = metadata.format ?? "EXIF"
        metadataCard.isHidden = false
        metadataCardHeightConstraint?.update(offset: 140)
        metadataCard.configure(
            title: title,
            line1: line1,
            line2: line2,
            line3: metadataLine3,
            format: format,
            latitude: metadata.latitude,
            longitude: metadata.longitude
        )
    }

    private func extractMetadata(from url: URL) -> PhotoMetadata? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }

        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any]

        let model = tiff?[kCGImagePropertyTIFFModel] as? String
        let make = tiff?[kCGImagePropertyTIFFMake] as? String
        let camera = [make, model]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let lensInfo = exif?[kCGImagePropertyExifLensModel] as? String
        let focalLength = exif?[kCGImagePropertyExifFocalLength] as? Double
        let aperture = exif?[kCGImagePropertyExifFNumber] as? Double
        let iso: Int? = {
            if let values = exif?[kCGImagePropertyExifISOSpeedRatings] as? [NSNumber],
               let first = values.first {
                return first.intValue
            }
            return exif?[kCGImagePropertyExifISOSpeedRatings] as? Int
        }()

        let pixelWidth = props[kCGImagePropertyPixelWidth] as? Int
        let pixelHeight = props[kCGImagePropertyPixelHeight] as? Int

        let fileSize: Double? = {
            guard let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize else { return nil }
            return Double(size)
        }()

        let format = url.pathExtension.uppercased()

        let latitude = resolveCoordinate(value: gps?[kCGImagePropertyGPSLatitude], ref: gps?[kCGImagePropertyGPSLatitudeRef])
        let longitude = resolveCoordinate(value: gps?[kCGImagePropertyGPSLongitude], ref: gps?[kCGImagePropertyGPSLongitudeRef])

        return PhotoMetadata(
            camera: camera.isEmpty ? nil : camera,
            lensInfo: lensInfo,
            focalLength: focalLength,
            aperture: aperture,
            shutterSpeed: nil,
            iso: iso,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            fileSize: fileSize,
            format: format.isEmpty ? nil : format,
            whiteBalance: nil,
            location: nil,
            takenAt: nil,
            latitude: latitude,
            longitude: longitude
        )
    }

    private func resolveCoordinate(value: Any?, ref: Any?) -> Double? {
        guard let raw = value as? Double else { return nil }
        let refString = ref as? String
        if refString == "S" || refString == "W" {
            return -raw
        }
        return raw
    }

    private func mappedLensInfo(from metadata: PhotoMetadata) -> String? {
        let lensText = metadata.lensInfo?.lowercased() ?? ""
        if lensText.contains("ultra") || lensText.contains("uw") {
            return "울트라 와이드 카메라"
        }
        if lensText.contains("tele") || lensText.contains("zoom") {
            return "망원 카메라"
        }
        if lensText.contains("wide") || lensText.contains("standard") {
            return "와이드 카메라"
        }
        if let focal = metadata.focalLength {
            if focal <= 13.0 {
                return "울트라 와이드 카메라"
            }
            if focal <= 26.0 {
                return "와이드 카메라"
            }
            return "망원 카메라"
        }
        return metadata.lensInfo
    }

    private func normalizedMetadata(_ metadata: PhotoMetadata) -> PhotoMetadata {
        PhotoMetadata(
            camera: metadata.camera,
            lensInfo: mappedLensInfo(from: metadata),
            focalLength: metadata.focalLength,
            aperture: metadata.aperture,
            shutterSpeed: metadata.shutterSpeed,
            iso: metadata.iso,
            pixelWidth: metadata.pixelWidth,
            pixelHeight: metadata.pixelHeight,
            fileSize: metadata.fileSize,
            format: metadata.format,
            whiteBalance: metadata.whiteBalance,
            location: metadata.location,
            takenAt: metadata.takenAt,
            latitude: metadata.latitude,
            longitude: metadata.longitude
        )
    }

    private func updateLocationText(latitude: Double?, longitude: Double?) {
        guard let latitude, let longitude else {
            metadataLine3 = ""
            return
        }
        metadataLine3 = "위치 확인 중"
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let place = placemarks?.first
            let address = [
                place?.administrativeArea,
                place?.locality,
                place?.thoroughfare,
                place?.subThoroughfare
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            self.metadataLine3 = address
            self.updateMetadataCard(with: self.currentMetadata)
        }
    }

    private func makeMetadata(from image: UIImage) -> PhotoMetadata {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        let fileSize = image.jpegData(compressionQuality: 1.0).map { Double($0.count) }
        return PhotoMetadata(
            camera: nil,
            lensInfo: nil,
            focalLength: nil,
            aperture: nil,
            shutterSpeed: nil,
            iso: nil,
            pixelWidth: width,
            pixelHeight: height,
            fileSize: fileSize,
            format: "JPG",
            whiteBalance: nil,
            location: nil,
            takenAt: nil,
            latitude: nil,
            longitude: nil
        )
    }

    private func updatePhotoHeight() {
        let targetHeight: CGFloat
        if isPhotoSquare {
            targetHeight = max(0, view.bounds.width - 40)
        } else {
            targetHeight = 90
        }
        photoHeightConstraint?.update(offset: targetHeight)
    }

    private func updateSaveButtonState() {
        saveButton.isEnabled = isSaveEnabled && !isSaving
        saveButton.tintColor = saveButton.isEnabled ? .brightTurquoise : .gray60
    }

    private func categoryButtonTag(for category: FilterMakeCategory) -> Int {
        switch category {
        case .food: return 1
        case .people: return 2
        case .landscape: return 3
        case .night: return 4
        case .star: return 5
        }
    }

    private func categoryForTag(_ tag: Int) -> FilterMakeCategory? {
        switch tag {
        case 1: return .food
        case 2: return .people
        case 3: return .landscape
        case 4: return .night
        case 5: return .star
        default: return nil
        }
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

    private func presentCreateSuccess(title: String) {
        let alert = UIAlertController(title: "완료", message: "\"\(title)\" 필터가 등록되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func nameChanged() {
        titleChangedSubject.send(nameTextField.text ?? "")
    }

    @objc private func priceChanged() {
        priceChangedSubject.send(priceTextField.text ?? "")
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        guard let category = categoryForTag(sender.tag) else { return }
        categorySelectedSubject.send(category)
    }

    @objc private func photoTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func editTapped() {
        let draft = FilterMakeDraft(
            title: nameTextField.text ?? "",
            category: selectedCategory,
            description: descriptionTextView.text ?? "",
            priceText: priceTextField.text ?? "",
            image: photoImageView.image
        )
        let editVM = viewModel.makeEditViewModel(draft: draft, adjustments: currentAdjustments)
        let editVC = FilterMakeEditViewController(viewModel: editVM)
        editVC.onAdjustmentsUpdated = { [weak self] values in
            self?.currentAdjustments = values
        }
        navigationController?.pushViewController(editVC, animated: true)
    }

    @objc private func saveTapped() {
        saveTappedSubject.send(())
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

}

extension FilterMakeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        let group = DispatchGroup()
        var pickedImage: UIImage?
        var pickedMetadata: PhotoMetadata?

        if provider.canLoadObject(ofClass: UIImage.self) {
            group.enter()
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                pickedImage = object as? UIImage
                group.leave()
            }
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            group.enter()
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
                if let url {
                    pickedMetadata = self.extractMetadata(from: url)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self, let image = pickedImage else { return }
            self.imageSelectedSubject.send(image)
            let rawMetadata = pickedMetadata ?? self.makeMetadata(from: image)
            let metadata = self.normalizedMetadata(rawMetadata)
            self.currentMetadata = metadata
            self.metadataLine3 = ""
            self.updateMetadataCard(with: metadata)
            self.updateLocationText(latitude: metadata.latitude, longitude: metadata.longitude)
            self.metadataSelectedSubject.send(metadata)
        }
    }
}

extension FilterMakeViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        descriptionPlaceholderLabel.isHidden = !text.isEmpty
        descriptionChangedSubject.send(text)
    }
}

extension FilterMakeViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField === priceTextField else { return }
        let digits = (textField.text ?? "").filter { $0.isNumber }
        if let value = Int(digits), value > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            textField.text = formatter.string(from: NSNumber(value: value))
        }
        priceChangedSubject.send(textField.text ?? "")
    }
}
