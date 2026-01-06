//
//  MyPageViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/30/25.
//

import Foundation
import Combine
import Kingfisher

final class MyPageViewModel: BaseViewModel, ViewModelType {
    private let authRepository: AuthRepository
    private let userRepository: UserRepository
    private let orderRepository: OrderRepository
    private let filterRepository: FilterRepository
    private let chatRepository: ChatRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String

    init(
        authRepository: AuthRepository,
        userRepository: UserRepository,
        orderRepository: OrderRepository,
        filterRepository: FilterRepository,
        chatRepository: ChatRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        self.orderRepository = orderRepository
        self.filterRepository = filterRepository
        self.chatRepository = chatRepository
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
        super.init()
    }

    var imageHeaders: [String: String] {
        var headers: [String: String] = ["SeSACKey": sesacKey]
        if let token = accessTokenProvider(), token.isEmpty == false {
            headers["Authorization"] = token
        }
        return headers
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refresh: AnyPublisher<Void, Never>
        let logoutTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let profile: AnyPublisher<UserProfile?, Never>
        let logoutCompleted: AnyPublisher<Void, Never>
    }

    func transform(input: Input) -> Output {
        let profileSubject = CurrentValueSubject<UserProfile?, Never>(nil)
        let logoutSubject = PassthroughSubject<Void, Never>()

        Publishers.Merge(input.viewDidLoad, input.refresh)
            .flatMap { [weak self] _ -> AnyPublisher<UserProfile, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.userRepository.fetchMyProfile()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { profile in
                profileSubject.send(profile)
            }
            .store(in: &cancellables)

        input.logoutTapped
            .flatMap { [weak self] _ -> AnyPublisher<Void, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.authRepository.updateDeviceToken("Logout")
                    .flatMap { self.authRepository.logout() }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading.send(false)
                if case let .failure(error) = completion {
                    self.error.send(error)
                }
            } receiveValue: { [weak self] in
                guard let self else { return }
                self.clearLocalData()
                logoutSubject.send(())
            }
            .store(in: &cancellables)

        return Output(
            profile: profileSubject.eraseToAnyPublisher(),
            logoutCompleted: logoutSubject.eraseToAnyPublisher()
        )
    }

    private func clearLocalData() {
        let defaults = UserDefaults.standard
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        defaults.synchronize()

        URLCache.shared.removeAllCachedResponses()
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()

        let fileManager = FileManager.default
        let cacheURLs = [
            fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
            fileManager.temporaryDirectory
        ].compactMap { $0 }

        cacheURLs.forEach { url in
            let contents = (try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
            contents.forEach { try? fileManager.removeItem(at: $0) }
        }
    }
}

extension MyPageViewModel {
    func makeEditViewModel(initialProfile: UserProfile?) -> MyPageEditViewModel {
        MyPageEditViewModel(
            userRepository: userRepository,
            initialProfile: initialProfile,
            accessTokenProvider: accessTokenProvider,
            sesacKey: sesacKey
        )
    }

    func makePurchaseHistoryViewModel() -> PurchaseHistoryViewModel {
        PurchaseHistoryViewModel(orderRepository: orderRepository)
    }

    func makeLikedFilterViewModel() -> LikedFilterViewModel {
        LikedFilterViewModel(
            filterRepository: filterRepository,
            accessTokenProvider: accessTokenProvider,
            sesacKey: sesacKey
        )
    }

    func makeMyUploadViewModel(userID: String) -> MyUploadViewModel {
        MyUploadViewModel(
            filterRepository: filterRepository,
            userID: userID,
            accessTokenProvider: accessTokenProvider,
            sesacKey: sesacKey
        )
    }

    func makeMyChattingListViewModel() -> MyChattingListViewModel {
        MyChattingListViewModel(
            chatRepository: chatRepository,
            userRepository: userRepository,
            accessTokenProvider: accessTokenProvider,
            sesacKey: sesacKey
        )
    }
}
