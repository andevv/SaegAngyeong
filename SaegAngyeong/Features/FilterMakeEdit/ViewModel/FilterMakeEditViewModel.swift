//
//  FilterMakeEditViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/29/25.
//

import UIKit
import Combine
import CoreImage

struct FilterMakeDraft {
    var title: String
    var category: FilterMakeCategory?
    var description: String
    var priceText: String
    var image: UIImage?
}

struct FilterAdjustmentValues: Equatable {
    var brightness: Double
    var exposure: Double
    var contrast: Double
    var saturation: Double
    var sharpness: Double
    var highlights: Double
    var shadows: Double
    var temperature: Double
    var vignette: Double
    var noiseReduction: Double
    var blur: Double
    var blackPoint: Double

    static let defaultValues = FilterAdjustmentValues(
        brightness: 0,
        exposure: 0,
        contrast: 1,
        saturation: 1,
        sharpness: 0,
        highlights: 0,
        shadows: 0,
        temperature: 6500,
        vignette: 0,
        noiseReduction: 0,
        blur: 0,
        blackPoint: 0
    )
}

enum FilterAdjustmentType: CaseIterable {
    case brightness
    case exposure
    case contrast
    case saturation
    case sharpness
    case highlights
    case shadows
    case temperature
    case vignette
    case noiseReduction
    case blur
    case blackPoint

    var title: String {
        switch self {
        case .brightness: return "BRIGHTNESS"
        case .exposure: return "EXPOSURE"
        case .contrast: return "CONTRAST"
        case .saturation: return "SATURATION"
        case .sharpness: return "SHARPNESS"
        case .highlights: return "HIGHLIGHTS"
        case .shadows: return "SHADOWS"
        case .temperature: return "TEMPERATURE"
        case .vignette: return "VIGNETTE"
        case .noiseReduction: return "NOISE"
        case .blur: return "BLUR"
        case .blackPoint: return "BLACK"
        }
    }

    var iconName: String {
        switch self {
        case .brightness: return "Brightness"
        case .exposure: return "Exposure"
        case .contrast: return "Contrast"
        case .saturation: return "Saturation"
        case .sharpness: return "Sharpness"
        case .highlights: return "Highlights"
        case .shadows: return "Shadows"
        case .temperature: return "Temperature"
        case .vignette: return "Vignette"
        case .noiseReduction: return "Noise"
        case .blur: return "Blur"
        case .blackPoint: return "BlackPoint"
        }
    }

}

final class FilterMakeEditViewModel: BaseViewModel, ViewModelType {
    private let filterRepository: FilterRepository
    private var draft: FilterMakeDraft
    private var adjustments: FilterAdjustmentValues
    private let baselineAdjustments: FilterAdjustmentValues
    private var history: [FilterAdjustmentValues]
    private var historyIndex: Int
    private let maxHistory = 40

    private let processingQueue = DispatchQueue(label: "filter.make.edit.processing")
    private let ciContext = CIContext(options: nil)
    private var originalImage: UIImage?
    private var originalCIImage: CIImage?
    private var currentFilteredImage: UIImage?
    private var pendingWorkItem: DispatchWorkItem?

    init(
        filterRepository: FilterRepository,
        draft: FilterMakeDraft,
        adjustments: FilterAdjustmentValues
    ) {
        self.filterRepository = filterRepository
        self.draft = draft
        self.adjustments = adjustments
        self.baselineAdjustments = .defaultValues
        self.history = [adjustments]
        self.historyIndex = 0
        super.init()
        self.originalImage = draft.image
        if let image = draft.image {
            self.originalCIImage = CIImage(image: image)
        }
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let adjustmentSelected: AnyPublisher<FilterAdjustmentType, Never>
        let sliderValueChanged: AnyPublisher<Double, Never>
        let sliderEditingEnded: AnyPublisher<Double, Never>
        let undoTapped: AnyPublisher<Void, Never>
        let redoTapped: AnyPublisher<Void, Never>
        let saveTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let previewImage: AnyPublisher<UIImage?, Never>
        let selectedAdjustment: AnyPublisher<FilterAdjustmentType, Never>
        let currentValue: AnyPublisher<Double, Never>
        let undoEnabled: AnyPublisher<Bool, Never>
        let redoEnabled: AnyPublisher<Bool, Never>
        let isSaving: AnyPublisher<Bool, Never>
        let saveCompleted: AnyPublisher<Void, Never>
    }

    func transform(input: Input) -> Output {
        let previewSubject = CurrentValueSubject<UIImage?, Never>(originalImage)
        let selectedSubject = CurrentValueSubject<FilterAdjustmentType, Never>(.brightness)
        let valueSubject = CurrentValueSubject<Double, Never>(currentValue(for: .brightness))
        let undoSubject = CurrentValueSubject<Bool, Never>(false)
        let redoSubject = CurrentValueSubject<Bool, Never>(false)
        let savingSubject = CurrentValueSubject<Bool, Never>(false)
        let saveCompletedSubject = PassthroughSubject<Void, Never>()

        input.viewDidLoad
            .sink { [weak self] in
                self?.applyFiltersDebounced(to: previewSubject)
            }
            .store(in: &cancellables)

        input.adjustmentSelected
            .sink { [weak self] adjustment in
                guard let self else { return }
                selectedSubject.send(adjustment)
                valueSubject.send(self.currentValue(for: adjustment))
            }
            .store(in: &cancellables)

        input.sliderValueChanged
            .sink { [weak self] value in
                guard let self else { return }
                let selected = selectedSubject.value
                self.updateAdjustment(selected, value: value)
                valueSubject.send(value)
                self.applyFiltersDebounced(to: previewSubject)
            }
            .store(in: &cancellables)

        input.sliderEditingEnded
            .sink { [weak self] _ in
                guard let self else { return }
                self.commitHistory()
                let state = self.historyState()
                undoSubject.send(state.undoEnabled)
                redoSubject.send(state.redoEnabled)
            }
            .store(in: &cancellables)

        input.undoTapped
            .sink { [weak self] in
                guard let self else { return }
                self.undo()
                let selected = selectedSubject.value
                valueSubject.send(self.currentValue(for: selected))
                self.applyFiltersDebounced(to: previewSubject)
                let state = self.historyState()
                undoSubject.send(state.undoEnabled)
                redoSubject.send(state.redoEnabled)
            }
            .store(in: &cancellables)

        input.redoTapped
            .sink { [weak self] in
                guard let self else { return }
                self.redo()
                let selected = selectedSubject.value
                valueSubject.send(self.currentValue(for: selected))
                self.applyFiltersDebounced(to: previewSubject)
                let state = self.historyState()
                undoSubject.send(state.undoEnabled)
                redoSubject.send(state.redoEnabled)
            }
            .store(in: &cancellables)

        input.saveTapped
            .sink { [weak self] in
                self?.save(
                    savingSubject: savingSubject,
                    previewSubject: previewSubject,
                    saveCompletedSubject: saveCompletedSubject
                )
            }
            .store(in: &cancellables)

        return Output(
            previewImage: previewSubject.eraseToAnyPublisher(),
            selectedAdjustment: selectedSubject.eraseToAnyPublisher(),
            currentValue: valueSubject.eraseToAnyPublisher(),
            undoEnabled: undoSubject.eraseToAnyPublisher(),
            redoEnabled: redoSubject.eraseToAnyPublisher(),
            isSaving: savingSubject.eraseToAnyPublisher(),
            saveCompleted: saveCompletedSubject.eraseToAnyPublisher()
        )
    }

    func snapshotAdjustments() -> FilterAdjustmentValues {
        adjustments
    }

    func snapshotOriginalImage() -> UIImage? {
        originalImage
    }

    func baselineValue(for type: FilterAdjustmentType) -> Double {
        switch type {
        case .brightness: return baselineAdjustments.brightness
        case .exposure: return baselineAdjustments.exposure
        case .contrast: return baselineAdjustments.contrast
        case .saturation: return baselineAdjustments.saturation
        case .sharpness: return baselineAdjustments.sharpness
        case .highlights: return baselineAdjustments.highlights
        case .shadows: return baselineAdjustments.shadows
        case .temperature: return baselineAdjustments.temperature
        case .vignette: return baselineAdjustments.vignette
        case .noiseReduction: return baselineAdjustments.noiseReduction
        case .blur: return baselineAdjustments.blur
        case .blackPoint: return baselineAdjustments.blackPoint
        }
    }

    private func currentValue(for type: FilterAdjustmentType) -> Double {
        switch type {
        case .brightness: return adjustments.brightness
        case .exposure: return adjustments.exposure
        case .contrast: return adjustments.contrast
        case .saturation: return adjustments.saturation
        case .sharpness: return adjustments.sharpness
        case .highlights: return adjustments.highlights
        case .shadows: return adjustments.shadows
        case .temperature: return adjustments.temperature
        case .vignette: return adjustments.vignette
        case .noiseReduction: return adjustments.noiseReduction
        case .blur: return adjustments.blur
        case .blackPoint: return adjustments.blackPoint
        }
    }

    private func updateAdjustment(_ type: FilterAdjustmentType, value: Double) {
        switch type {
        case .brightness: adjustments.brightness = value
        case .exposure: adjustments.exposure = value
        case .contrast: adjustments.contrast = value
        case .saturation: adjustments.saturation = value
        case .sharpness: adjustments.sharpness = value
        case .highlights: adjustments.highlights = value
        case .shadows: adjustments.shadows = value
        case .temperature: adjustments.temperature = value
        case .vignette: adjustments.vignette = value
        case .noiseReduction: adjustments.noiseReduction = value
        case .blur: adjustments.blur = value
        case .blackPoint: adjustments.blackPoint = value
        }
    }

    private func historyState() -> (undoEnabled: Bool, redoEnabled: Bool) {
        let undoEnabled = historyIndex > 0
        let redoEnabled = historyIndex < history.count - 1
        return (undoEnabled, redoEnabled)
    }

    private func commitHistory() {
        guard history.last != adjustments else { return }
        if historyIndex < history.count - 1 {
            history = Array(history.prefix(historyIndex + 1))
        }
        history.append(adjustments)
        if history.count > maxHistory {
            history.removeFirst()
        } else {
            historyIndex += 1
        }
    }

    private func undo() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        adjustments = history[historyIndex]
    }

    private func redo() {
        guard historyIndex < history.count - 1 else { return }
        historyIndex += 1
        adjustments = history[historyIndex]
    }

    private func applyFiltersDebounced(to subject: CurrentValueSubject<UIImage?, Never>) {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let image = self.renderFilteredImage()
            DispatchQueue.main.async {
                subject.send(image)
            }
        }
        pendingWorkItem = workItem
        processingQueue.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }

    private func renderFilteredImage() -> UIImage? {
        guard let originalCIImage, let originalImage else { return nil }
        var output = originalCIImage
        output = applyColorControls(to: output)
        output = applyExposure(to: output)
        output = applyTemperature(to: output)
        output = applyHighlightShadow(to: output)
        output = applySharpen(to: output)
        output = applyNoiseReduction(to: output)
        output = applyVignette(to: output)
        output = applyBlur(to: output)
        output = applyBlackPoint(to: output)
        output = output.cropped(to: originalCIImage.extent)
        guard let cgImage = ciContext.createCGImage(output, from: originalCIImage.extent) else { return nil }
        let image = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        currentFilteredImage = image
        return image
    }

    private func applyColorControls(to input: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return input }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(adjustments.brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(adjustments.contrast, forKey: kCIInputContrastKey)
        filter.setValue(adjustments.saturation, forKey: kCIInputSaturationKey)
        return filter.outputImage ?? input
    }

    private func applyExposure(to input: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIExposureAdjust") else { return input }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(adjustments.exposure, forKey: kCIInputEVKey)
        return filter.outputImage ?? input
    }

    private func applyTemperature(to input: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CITemperatureAndTint") else { return input }
        filter.setValue(input, forKey: kCIInputImageKey)
        let neutral = CIVector(x: 6500, y: 0)
        let target = CIVector(x: CGFloat(adjustments.temperature), y: 0)
        filter.setValue(neutral, forKey: "inputNeutral")
        filter.setValue(target, forKey: "inputTargetNeutral")
        return filter.outputImage ?? input
    }

    private func applyHighlightShadow(to input: CIImage) -> CIImage {
        guard adjustments.highlights != 0 || adjustments.shadows != 0 else { return input }
        guard let filter = CIFilter(name: "CIHighlightShadowAdjust") else { return input }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(adjustments.shadows, forKey: "inputShadowAmount")
        filter.setValue(1 - adjustments.highlights, forKey: "inputHighlightAmount")
        return filter.outputImage ?? input
    }

    private func applySharpen(to input: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CISharpenLuminance") else { return input }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(adjustments.sharpness, forKey: "inputSharpness")
        return filter.outputImage ?? input
    }

    private func applyNoiseReduction(to input: CIImage) -> CIImage {
        guard adjustments.noiseReduction > 0 else { return input }
        guard let filter = CIFilter(name: "CINoiseReduction") else { return input }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(adjustments.noiseReduction * 0.1, forKey: "inputNoiseLevel")
        filter.setValue(0.4, forKey: "inputSharpness")
        return filter.outputImage ?? input
    }

    private func applyVignette(to input: CIImage) -> CIImage {
        guard adjustments.vignette > 0 else { return input }
        guard let filter = CIFilter(name: "CIVignette") else { return input }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(adjustments.vignette * 2, forKey: kCIInputIntensityKey)
        filter.setValue(2, forKey: kCIInputRadiusKey)
        return filter.outputImage ?? input
    }

    private func applyBlur(to input: CIImage) -> CIImage {
        guard adjustments.blur > 0 else { return input }
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return input }
        let clamped = input.clampedToExtent()
        filter.setValue(clamped, forKey: kCIInputImageKey)
        filter.setValue(adjustments.blur * 2, forKey: kCIInputRadiusKey)
        return filter.outputImage?.cropped(to: input.extent) ?? input
    }

    private func applyBlackPoint(to input: CIImage) -> CIImage {
        guard adjustments.blackPoint > 0 else { return input }
        guard let filter = CIFilter(name: "CIColorClamp") else { return input }
        filter.setValue(input, forKey: kCIInputImageKey)
        let minVector = CIVector(x: CGFloat(adjustments.blackPoint), y: CGFloat(adjustments.blackPoint), z: CGFloat(adjustments.blackPoint), w: 0)
        let maxVector = CIVector(x: 1, y: 1, z: 1, w: 1)
        filter.setValue(minVector, forKey: "inputMinComponents")
        filter.setValue(maxVector, forKey: "inputMaxComponents")
        return filter.outputImage ?? input
    }

    private func save(
        savingSubject: CurrentValueSubject<Bool, Never>,
        previewSubject: CurrentValueSubject<UIImage?, Never>,
        saveCompletedSubject: PassthroughSubject<Void, Never>
    ) {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let priceValue = Self.parsePrice(from: draft.priceText)

        guard let category = draft.category else {
            error.send(DomainError.validation(message: "카테고리를 선택해주세요."))
            return
        }
        guard !trimmedTitle.isEmpty else {
            error.send(DomainError.validation(message: "필터명을 입력해주세요."))
            return
        }
        guard !trimmedDesc.isEmpty else {
            error.send(DomainError.validation(message: "필터 소개를 입력해주세요."))
            return
        }
        guard priceValue > 0 else {
            error.send(DomainError.validation(message: "판매 가격을 입력해주세요."))
            return
        }
        guard let originalImage = draft.image else {
            error.send(DomainError.validation(message: "대표 사진을 등록해주세요."))
            return
        }

        let filteredImage = currentFilteredImage ?? renderFilteredImage()
        guard let filteredImage else {
            error.send(DomainError.validation(message: "필터 이미지를 생성할 수 없습니다."))
            return
        }
        guard let originalData = Self.makeUploadData(from: originalImage),
              let filteredData = Self.makeUploadData(from: filteredImage) else {
            error.send(DomainError.validation(message: "이미지 용량이 너무 큽니다. 2MB 이하로 줄여주세요."))
            return
        }

        let uploadFiles = [
            UploadFileData(data: originalData, fileName: "filter_original.jpg", mimeType: "image/jpeg"),
            UploadFileData(data: filteredData, fileName: "filter_filtered.jpg", mimeType: "image/jpeg")
        ]

        savingSubject.send(true)
        isLoading.send(true)

        filterRepository.uploadFiles(uploadFiles)
            .flatMap { [weak self] urls -> AnyPublisher<Filter, DomainError> in
                guard let self else { return Fail(error: DomainError.unknown(message: nil)).eraseToAnyPublisher() }
                let filePaths = urls.map { Self.normalizeFilePath(from: $0) }
                let draft = FilterDraft(
                    category: category.apiValue,
                    title: trimmedTitle,
                    price: priceValue,
                    description: trimmedDesc,
                    files: filePaths,
                    photoMetadata: nil,
                    filterValues: self.makeFilterValues()
                )
                return self.filterRepository.create(draft)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                savingSubject.send(false)
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { _ in
                saveCompletedSubject.send(())
            }
            .store(in: &cancellables)
    }

    private func makeFilterValues() -> FilterValues {
        let deltas = deltaAdjustments()
        return FilterValues(
            brightness: deltas.brightness,
            exposure: deltas.exposure,
            contrast: deltas.contrast,
            saturation: deltas.saturation,
            sharpness: deltas.sharpness,
            noiseReduction: deltas.noiseReduction,
            temperature: adjustments.temperature,
            highlight: deltas.highlights,
            shadow: deltas.shadows,
            vignette: deltas.vignette,
            grain: nil,
            blur: deltas.blur,
            fade: nil,
            blackPoint: deltas.blackPoint
        )
    }

    private func deltaAdjustments() -> FilterAdjustmentValues {
        FilterAdjustmentValues(
            brightness: adjustments.brightness - baselineAdjustments.brightness,
            exposure: adjustments.exposure - baselineAdjustments.exposure,
            contrast: adjustments.contrast - baselineAdjustments.contrast,
            saturation: adjustments.saturation - baselineAdjustments.saturation,
            sharpness: adjustments.sharpness - baselineAdjustments.sharpness,
            highlights: adjustments.highlights - baselineAdjustments.highlights,
            shadows: adjustments.shadows - baselineAdjustments.shadows,
            temperature: adjustments.temperature,
            vignette: adjustments.vignette - baselineAdjustments.vignette,
            noiseReduction: adjustments.noiseReduction - baselineAdjustments.noiseReduction,
            blur: adjustments.blur - baselineAdjustments.blur,
            blackPoint: adjustments.blackPoint - baselineAdjustments.blackPoint
        )
    }

    private static func parsePrice(from text: String) -> Int {
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 0
    }

    private static func normalizeFilePath(from url: URL) -> String {
        let path = url.path
        if path.hasPrefix("/v1/") {
            let trimmed = String(path.dropFirst(3))
            return trimmed.hasPrefix("/") ? trimmed : "/" + trimmed
        }
        return path
    }

    private static func makeUploadData(from image: UIImage, maxBytes: Int = 2 * 1024 * 1024) -> Data? {
        let resized = resizeToScreenSizeIfNeeded(image)
        if let data = resized.jpegData(compressionQuality: 0.9), data.count <= maxBytes {
            return data
        }

        let qualities: [CGFloat] = [0.85, 0.75, 0.65, 0.55, 0.45]
        for quality in qualities {
            if let data = resized.jpegData(compressionQuality: quality), data.count <= maxBytes {
                return data
            }
        }
        return nil
    }

    private static func resizeToScreenSizeIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1080
        let width = image.size.width
        let height = image.size.height
        let maxSide = max(width, height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: width * scale, height: height * scale)
        return image.resized(to: newSize) ?? image
    }
}

private extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
