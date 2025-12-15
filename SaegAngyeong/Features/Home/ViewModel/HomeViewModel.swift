//
//  HomeViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Combine

final class HomeViewModel: BaseViewModel, ViewModelType {

    private let filterRepository: FilterRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String

    init(
        filterRepository: FilterRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.filterRepository = filterRepository
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
        super.init()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
    }

    struct Output {
        let highlight: AnyPublisher<HighlightViewData, Never>
    }

    func transform(input: Input) -> Output {
        let highlightSubject = PassthroughSubject<HighlightViewData, Never>()

        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<Filter, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.filterRepository.todayFilter()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { filter in
                let viewData = HighlightViewData(
                    title: filter.title,
                    introduction: filter.introduction ?? "",
                    description: filter.description,
                    imageURL: filter.files.first,
                    headers: self.imageHeaders
                )
                highlightSubject.send(viewData)
            }
            .store(in: &cancellables)

        return Output(
            highlight: highlightSubject.eraseToAnyPublisher()
        )
    }
}

struct HighlightViewData {
    let title: String
    let introduction: String
    let description: String
    let imageURL: URL?
    let headers: [String: String]
}

extension HomeViewModel {
    var imageHeaders: [String: String] {
        var headers: [String: String] = ["SeSACKey": sesacKey]
        if let token = accessTokenProvider(), !token.isEmpty {
            headers["Authorization"] = token
        }
        return headers
    }
}
