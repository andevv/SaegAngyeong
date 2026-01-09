//
//  FilterMakeEditViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/29/25.
//

import UIKit
import SnapKit
import Combine

final class FilterMakeEditViewController: BaseViewController<FilterMakeEditViewModel> {
    private let imageContainer = UIView()
    private let imageView = UIImageView()
    private let undoButton = UIButton(type: .system)
    private let redoButton = UIButton(type: .system)
    private let compareButton = UIButton(type: .system)

    private let valueLabel = UILabel()
    private let slider = UISlider()
    private lazy var adjustmentCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.itemSize = CGSize(width: 60, height: 64)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FilterAdjustmentCell.self, forCellWithReuseIdentifier: FilterAdjustmentCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let adjustmentSelectedSubject = PassthroughSubject<FilterAdjustmentType, Never>()
    private let sliderValueChangedSubject = PassthroughSubject<Double, Never>()
    private let sliderEditingEndedSubject = PassthroughSubject<Double, Never>()
    private let undoTappedSubject = PassthroughSubject<Void, Never>()
    private let redoTappedSubject = PassthroughSubject<Void, Never>()
    private let saveTappedSubject = PassthroughSubject<Void, Never>()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "EDIT"
        label.textColor = .gray60
        label.font = .mulgyeol(.bold, size: 18)
        return label
    }()

    private var originalImage: UIImage?
    private var currentFilteredImage: UIImage?
    private var selectedAdjustment: FilterAdjustmentType = .brightness

    var onAdjustmentsUpdated: ((FilterAdjustmentValues) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        originalImage = viewModel.snapshotOriginalImage()
        viewDidLoadSubject.send(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        onAdjustmentsUpdated?(viewModel.snapshotAdjustments())
    }

    override func configureUI() {
        navigationItem.titleView = titleLabel

        let saveButton = UIButton(type: .system)
        saveButton.setImage(UIImage(named: "Icon_Save"), for: .normal)
        saveButton.tintColor = .gray60
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)

        imageContainer.backgroundColor = .blackTurquoise

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        undoButton.setImage(UIImage(named: "Icon_Undo"), for: .normal)
        undoButton.tintColor = .gray60
        undoButton.backgroundColor = UIColor.gray100.withAlphaComponent(0.35)
        undoButton.layer.cornerRadius = 10
        undoButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)

        redoButton.setImage(UIImage(named: "Icon_Redo"), for: .normal)
        redoButton.tintColor = .gray60
        redoButton.backgroundColor = UIColor.gray100.withAlphaComponent(0.35)
        redoButton.layer.cornerRadius = 10
        redoButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        redoButton.addTarget(self, action: #selector(redoTapped), for: .touchUpInside)

        compareButton.setImage(UIImage(named: "Icon_Compare"), for: .normal)
        compareButton.tintColor = .gray60
        compareButton.backgroundColor = UIColor.gray100.withAlphaComponent(0.35)
        compareButton.layer.cornerRadius = 10
        compareButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        compareButton.addTarget(self, action: #selector(compareTouchDown), for: .touchDown)
        compareButton.addTarget(self, action: #selector(compareTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        valueLabel.textColor = .gray60
        valueLabel.font = .pretendard(.medium, size: 12)
        valueLabel.textAlignment = .center

        slider.minimumTrackTintColor = .brightTurquoise
        slider.maximumTrackTintColor = .gray15
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderEditingEnded(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        view.addSubview(imageContainer)
        imageContainer.addSubview(imageView)
        imageContainer.addSubview(undoButton)
        imageContainer.addSubview(redoButton)
        imageContainer.addSubview(compareButton)
        view.addSubview(valueLabel)
        view.addSubview(slider)
        view.addSubview(adjustmentCollectionView)
    }

    override func configureLayout() {
        imageContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(imageContainer.snp.width).multipliedBy(4.0 / 3.0)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        undoButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().inset(12)
            make.width.height.equalTo(36)
        }

        redoButton.snp.makeConstraints { make in
            make.leading.equalTo(undoButton.snp.trailing).offset(10)
            make.centerY.equalTo(undoButton)
            make.width.height.equalTo(36)
        }

        compareButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(undoButton)
            make.width.height.equalTo(36)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }

        slider.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        adjustmentCollectionView.snp.makeConstraints { make in
            make.top.equalTo(slider.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(72)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-16)
        }
    }

    override func bindViewModel() {
        let input = FilterMakeEditViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            adjustmentSelected: adjustmentSelectedSubject.eraseToAnyPublisher(),
            sliderValueChanged: sliderValueChangedSubject.eraseToAnyPublisher(),
            sliderEditingEnded: sliderEditingEndedSubject.eraseToAnyPublisher(),
            undoTapped: undoTappedSubject.eraseToAnyPublisher(),
            redoTapped: redoTappedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.previewImage
            .sink { [weak self] image in
                self?.currentFilteredImage = image
                if self?.compareButton.isHighlighted == true {
                    return
                }
                self?.imageView.image = image
            }
            .store(in: &cancellables)

        output.selectedAdjustment
            .sink { [weak self] adjustment in
                self?.selectedAdjustment = adjustment
                self?.updateSlider(for: adjustment)
                self?.adjustmentCollectionView.reloadData()
            }
            .store(in: &cancellables)

        output.currentValue
            .sink { [weak self] value in
                guard let self else { return }
                let adjustment = self.selectedAdjustment
                self.updateValueLabel(value: value, adjustment: adjustment)
                self.slider.value = Float(self.sliderValue(for: adjustment, actualValue: value))
            }
            .store(in: &cancellables)

        output.undoEnabled
            .sink { [weak self] enabled in
                self?.undoButton.isEnabled = enabled
                self?.undoButton.tintColor = enabled ? .gray60 : .gray45
            }
            .store(in: &cancellables)

        output.redoEnabled
            .sink { [weak self] enabled in
                self?.redoButton.isEnabled = enabled
                self?.redoButton.tintColor = enabled ? .gray60 : .gray45
            }
            .store(in: &cancellables)

        output.isSaving
            .sink { [weak self] saving in
                self?.navigationItem.rightBarButtonItem?.customView?.isUserInteractionEnabled = !saving
            }
            .store(in: &cancellables)

        output.saveCompleted
            .sink { [weak self] in
                self?.presentSaveSuccess()
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func updateSlider(for adjustment: FilterAdjustmentType) {
        if adjustment == .temperature {
            slider.minimumValue = 3500
            slider.maximumValue = 7500
        } else {
            slider.minimumValue = -10
            slider.maximumValue = 10
        }
    }

    private func updateValueLabel(value: Double, adjustment: FilterAdjustmentType) {
        let displayValue: Double
        if adjustment == .temperature {
            displayValue = value
        } else {
            displayValue = sliderValue(for: adjustment, actualValue: value)
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = displayValue >= 1000 ? 0 : 1
        formatter.minimumFractionDigits = displayValue >= 1000 ? 0 : 1
        let text = formatter.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)"
        valueLabel.text = text
    }

    private func presentSaveSuccess() {
        let alert = UIAlertController(title: "완료", message: "필터 업로드가 완료되었습니다.", preferredStyle: .alert)
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

    @objc private func sliderChanged(_ sender: UISlider) {
        let adjustment = selectedAdjustment
        let snappedValue = snappedSliderValue(sender.value, adjustment: adjustment)
        sender.value = snappedValue
        let actualValue = actualValue(from: Double(snappedValue), adjustment: adjustment)
        sliderValueChangedSubject.send(actualValue)
    }

    @objc private func sliderEditingEnded(_ sender: UISlider) {
        let adjustment = selectedAdjustment
        let snappedValue = snappedSliderValue(sender.value, adjustment: adjustment)
        sender.value = snappedValue
        let actualValue = actualValue(from: Double(snappedValue), adjustment: adjustment)
        sliderEditingEndedSubject.send(actualValue)
    }

    @objc private func undoTapped() {
        undoTappedSubject.send(())
    }

    @objc private func redoTapped() {
        redoTappedSubject.send(())
    }

    @objc private func compareTouchDown() {
        imageView.image = originalImage ?? currentFilteredImage
    }

    @objc private func compareTouchUp() {
        imageView.image = currentFilteredImage
    }

    @objc private func saveTapped() {
        let adjustment = selectedAdjustment
        let snappedValue = snappedSliderValue(slider.value, adjustment: adjustment)
        slider.value = snappedValue
        let actualValue = actualValue(from: Double(snappedValue), adjustment: adjustment)
        sliderValueChangedSubject.send(actualValue)
        sliderEditingEndedSubject.send(actualValue)
        saveTappedSubject.send(())
    }

    private func sliderValue(for adjustment: FilterAdjustmentType, actualValue: Double) -> Double {
        if adjustment == .temperature {
            return actualValue
        }
        let delta = actualValue - viewModel.baselineValue(for: adjustment)
        return delta / scaleFactor(for: adjustment)
    }

    private func actualValue(from sliderValue: Double, adjustment: FilterAdjustmentType) -> Double {
        if adjustment == .temperature {
            return sliderValue
        }
        return viewModel.baselineValue(for: adjustment) + (sliderValue * scaleFactor(for: adjustment))
    }

    private func snappedSliderValue(_ value: Float, adjustment: FilterAdjustmentType) -> Float {
        if adjustment == .temperature {
            let snapped = (Double(value) / 50).rounded() * 50
            return Float(snapped)
        }
        let snapped = (Double(value) * 10).rounded() / 10
        return Float(snapped)
    }

    private func scaleFactor(for adjustment: FilterAdjustmentType) -> Double {
        adjustment == .temperature ? 1.0 : 0.1
    }
}

extension FilterMakeEditViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        FilterAdjustmentType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterAdjustmentCell.reuseID, for: indexPath) as? FilterAdjustmentCell else {
            return UICollectionViewCell()
        }
        let adjustment = FilterAdjustmentType.allCases[indexPath.item]
        cell.configure(
            iconName: adjustment.iconName,
            title: adjustment.title,
            isSelected: adjustment == selectedAdjustment
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let adjustment = FilterAdjustmentType.allCases[indexPath.item]
        adjustmentSelectedSubject.send(adjustment)
    }
}

private final class FilterAdjustmentCell: UICollectionViewCell {
    static let reuseID = "FilterAdjustmentCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .gray60

        titleLabel.font = .pretendard(.medium, size: 9)
        titleLabel.textColor = .gray60
        titleLabel.textAlignment = .center

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(iconName: String, title: String, isSelected: Bool) {
        iconView.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = title
        titleLabel.textColor = isSelected ? .gray30 : .gray60
        iconView.tintColor = isSelected ? .brightTurquoise : .gray60
        iconView.alpha = 1.0
    }
}
