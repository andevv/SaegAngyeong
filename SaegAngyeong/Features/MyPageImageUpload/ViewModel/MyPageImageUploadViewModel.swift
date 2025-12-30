//
//  MyPageImageUploadViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/30/25.
//

import UIKit
import Combine

final class MyPageImageUploadViewModel: BaseViewModel, ViewModelType {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        super.init()
    }

    struct Input {
        let imageSelected: AnyPublisher<UIImage?, Never>
        let uploadTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let previewImage: AnyPublisher<UIImage?, Never>
        let isUploading: AnyPublisher<Bool, Never>
        let uploadCompleted: AnyPublisher<URL, Never>
    }

    func transform(input: Input) -> Output {
        let previewSubject = CurrentValueSubject<UIImage?, Never>(nil)
        let uploadingSubject = CurrentValueSubject<Bool, Never>(false)
        let uploadCompletedSubject = PassthroughSubject<URL, Never>()

        input.imageSelected
            .sink { previewSubject.send($0) }
            .store(in: &cancellables)

        input.uploadTapped
            .sink { [weak self] in
                self?.upload(
                    image: previewSubject.value,
                    uploadingSubject: uploadingSubject,
                    completedSubject: uploadCompletedSubject
                )
            }
            .store(in: &cancellables)

        return Output(
            previewImage: previewSubject.eraseToAnyPublisher(),
            isUploading: uploadingSubject.eraseToAnyPublisher(),
            uploadCompleted: uploadCompletedSubject.eraseToAnyPublisher()
        )
    }

    private func upload(
        image: UIImage?,
        uploadingSubject: CurrentValueSubject<Bool, Never>,
        completedSubject: PassthroughSubject<URL, Never>
    ) {
        guard let image else {
            error.send(DomainError.validation(message: "프로필 이미지를 선택해주세요."))
            return
        }
        guard let data = Self.makeUploadData(from: image) else {
            error.send(DomainError.validation(message: "이미지 용량이 너무 큽니다. 1MB 이하로 줄여주세요."))
            return
        }

        uploadingSubject.send(true)
        isLoading.send(true)

        userRepository.uploadProfileImage(data: data, fileName: "profile.jpg", mimeType: "image/jpeg")
            .flatMap { [weak self] url -> AnyPublisher<UserProfile, DomainError> in
                guard let self else { return Fail(error: DomainError.unknown(message: nil)).eraseToAnyPublisher() }
                let update = UserProfileUpdate(
                    nick: nil,
                    name: nil,
                    introduction: nil,
                    description: nil,
                    phoneNumber: nil,
                    profileImageURL: url,
                    hashTags: nil
                )
                return self.userRepository.updateMyProfile(update)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                uploadingSubject.send(false)
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { profile in
                if let url = profile.profileImageURL {
                    completedSubject.send(url)
                }
            }
            .store(in: &cancellables)
    }

    private static func makeUploadData(from image: UIImage, maxBytes: Int = 1 * 1024 * 1024) -> Data? {
        let resized = resizeToScreenSizeIfNeeded(image)
        if let data = resized.jpegData(compressionQuality: 0.9), data.count <= maxBytes {
            return data
        }

        let qualities: [CGFloat] = [0.85, 0.75, 0.65, 0.55]
        for quality in qualities {
            if let data = resized.jpegData(compressionQuality: quality), data.count <= maxBytes {
                return data
            }
        }
        return nil
    }

    private static func resizeToScreenSizeIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 720
        let width = image.size.width
        let height = image.size.height
        let maxSide = max(width, height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: width * scale, height: height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
