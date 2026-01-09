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
        let streamURL: AnyPublisher<URL, Never>
    }

    private let streamURL: URL

    init(streamURL: URL) {
        self.streamURL = streamURL
        super.init()
    }

    func transform(input: Input) -> Output {
        let subject = CurrentValueSubject<URL, Never>(streamURL)
        input.viewDidLoad
            .sink { _ in }
            .store(in: &cancellables)
        return Output(streamURL: subject.eraseToAnyPublisher())
    }
}
