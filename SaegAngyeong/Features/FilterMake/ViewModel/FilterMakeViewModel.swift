//
//  FilterMakeViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/29/25.
//

import Foundation
import Combine
import UIKit

final class FilterMakeViewModel: BaseViewModel, ViewModelType {
    private let filterRepository: FilterRepository

    init(filterRepository: FilterRepository) {
        self.filterRepository = filterRepository
        super.init()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let titleChanged: AnyPublisher<String, Never>
        let categorySelected: AnyPublisher<FilterMakeCategory, Never>
        let descriptionChanged: AnyPublisher<String, Never>
        let priceChanged: AnyPublisher<String, Never>
        let imageSelected: AnyPublisher<UIImage?, Never>
        let saveTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let selectedCategory: AnyPublisher<FilterMakeCategory?, Never>
        let previewImage: AnyPublisher<UIImage?, Never>
        let isSaveEnabled: AnyPublisher<Bool, Never>
        let isSaving: AnyPublisher<Bool, Never>
        let createdFilter: AnyPublisher<Filter, Never>
    }

    func transform(input: Input) -> Output {
        let categorySubject = CurrentValueSubject<FilterMakeCategory?, Never>(nil)
        let titleSubject = CurrentValueSubject<String, Never>("")
        let descriptionSubject = CurrentValueSubject<String, Never>("")
        let priceSubject = CurrentValueSubject<String, Never>("")
        let imageSubject = CurrentValueSubject<UIImage?, Never>(nil)
        let saveEnabledSubject = CurrentValueSubject<Bool, Never>(false)
        let savingSubject = CurrentValueSubject<Bool, Never>(false)
        let createdSubject = PassthroughSubject<Filter, Never>()

        input.titleChanged
            .sink { titleSubject.send($0) }
            .store(in: &cancellables)

        input.categorySelected
            .sink { categorySubject.send($0) }
            .store(in: &cancellables)

        input.descriptionChanged
            .sink { descriptionSubject.send($0) }
            .store(in: &cancellables)

        input.priceChanged
            .sink { priceSubject.send($0) }
            .store(in: &cancellables)

        input.imageSelected
            .sink { imageSubject.send($0) }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            Publishers.CombineLatest4(titleSubject, descriptionSubject, priceSubject, imageSubject)
                .map { title, description, priceText, image in
                    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
                    let price = Self.parsePrice(from: priceText)
                    return !trimmedTitle.isEmpty && !trimmedDesc.isEmpty && price > 0 && image != nil
                },
            categorySubject
        )
        .map { baseEnabled, category in
            baseEnabled && category != nil
        }
        .removeDuplicates()
        .sink { saveEnabledSubject.send($0) }
        .store(in: &cancellables)

        input.saveTapped
            .sink { [weak self] in
                self?.createFilter(
                    category: categorySubject.value,
                    title: titleSubject.value,
                    description: descriptionSubject.value,
                    priceText: priceSubject.value,
                    image: imageSubject.value,
                    savingSubject: savingSubject,
                    createdSubject: createdSubject
                )
            }
            .store(in: &cancellables)

        return Output(
            selectedCategory: categorySubject.eraseToAnyPublisher(),
            previewImage: imageSubject.eraseToAnyPublisher(),
            isSaveEnabled: saveEnabledSubject.eraseToAnyPublisher(),
            isSaving: savingSubject.eraseToAnyPublisher(),
            createdFilter: createdSubject.eraseToAnyPublisher()
        )
    }

    private func createFilter(
        category: FilterMakeCategory?,
        title: String,
        description: String,
        priceText: String,
        image: UIImage?,
        savingSubject: CurrentValueSubject<Bool, Never>,
        createdSubject: PassthroughSubject<Filter, Never>
    ) {
        guard let category else {
            error.send(DomainError.validation(message: "카테고리를 선택해주세요."))
            return
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let price = Self.parsePrice(from: priceText)
        guard !trimmedTitle.isEmpty else {
            error.send(DomainError.validation(message: "필터명을 입력해주세요."))
            return
        }
        guard !trimmedDesc.isEmpty else {
            error.send(DomainError.validation(message: "필터 소개를 입력해주세요."))
            return
        }
        guard price > 0 else {
            error.send(DomainError.validation(message: "판매 가격을 입력해주세요."))
            return
        }
        guard let image else {
            error.send(DomainError.validation(message: "대표 사진을 등록해주세요."))
            return
        }
        guard let data = Self.makeUploadData(from: image) else {
            error.send(DomainError.validation(message: "이미지 용량이 너무 큽니다. 2MB 이하로 줄여주세요."))
            return
        }

        let uploadFiles = [
            UploadFileData(data: data, fileName: "filter_original.jpg", mimeType: "image/jpeg"),
            UploadFileData(data: data, fileName: "filter_filtered.jpg", mimeType: "image/jpeg")
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
                    price: price,
                    description: trimmedDesc,
                    files: filePaths,
                    photoMetadata: nil,
                    filterValues: Self.defaultFilterValues
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
            } receiveValue: { filter in
                createdSubject.send(filter)
            }
            .store(in: &cancellables)
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
        return resizedImage(image, to: newSize) ?? image
    }

    private static func resizedImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static let defaultFilterValues = FilterValues(
        brightness: 0,
        exposure: 0,
        contrast: 0,
        saturation: 0,
        sharpness: 0,
        noiseReduction: 0,
        temperature: 0,
        highlight: 0,
        shadow: 0,
        vignette: 0,
        grain: 0,
        blur: 0,
        fade: 0,
        blackPoint: 0
    )
}

extension FilterMakeViewModel {
    func makeEditViewModel(
        draft: FilterMakeDraft,
        adjustments: FilterAdjustmentValues
    ) -> FilterMakeEditViewModel {
        FilterMakeEditViewModel(
            filterRepository: filterRepository,
            draft: draft,
            adjustments: adjustments
        )
    }
}

enum FilterMakeCategory: String, CaseIterable {
    case food = "푸드"
    case people = "인물"
    case landscape = "풍경"
    case night = "야경"
    case star = "별"

    var title: String { rawValue }
    var apiValue: String { rawValue }
}
