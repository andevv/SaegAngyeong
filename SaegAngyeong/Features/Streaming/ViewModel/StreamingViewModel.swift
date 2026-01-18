//
//  StreamingViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 1/9/26.
//

import Foundation
import Combine

final class StreamingViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
    }

    struct Output {
        let streamInfo: AnyPublisher<StreamInfo, Never>
    }

    private let videoID: String
    private let videoRepository: VideoRepository

    init(videoID: String, videoRepository: VideoRepository) {
        self.videoID = videoID
        self.videoRepository = videoRepository
        super.init()
    }

    func transform(input: Input) -> Output {
        let subject = PassthroughSubject<StreamInfo, Never>()
        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<StreamInfo, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.videoRepository.streamInfo(videoID: self.videoID)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { info in
                subject.send(info)
            }
            .store(in: &cancellables)
        return Output(streamInfo: subject.eraseToAnyPublisher())
    }
}
