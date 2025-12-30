//
//  MyPageEditViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/30/25.
//

import Foundation
import Combine

struct MyPageEditDraft {
    let nick: String
    let name: String
    let introduction: String
    let phone: String
    let hashTagsText: String
    let profileImageURL: URL?
}

final class MyPageEditViewModel: BaseViewModel, ViewModelType {
    private let userRepository: UserRepository
    private let initialProfile: UserProfile?

    init(userRepository: UserRepository, initialProfile: UserProfile?) {
        self.userRepository = userRepository
        self.initialProfile = initialProfile
        super.init()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refresh: AnyPublisher<Void, Never>
        let saveTapped: AnyPublisher<MyPageEditDraft, Never>
    }

    struct Output {
        let profile: AnyPublisher<UserProfile?, Never>
        let saveCompleted: AnyPublisher<UserProfile, Never>
    }

    func transform(input: Input) -> Output {
        let profileSubject = CurrentValueSubject<UserProfile?, Never>(initialProfile)
        let saveCompletedSubject = PassthroughSubject<UserProfile, Never>()

        let delayedRefresh = input.refresh
            .delay(for: .milliseconds(1000), scheduler: DispatchQueue.main)

        Publishers.Merge(input.viewDidLoad, delayedRefresh)
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

        input.saveTapped
            .sink { [weak self] draft in
                self?.save(draft: draft, saveCompletedSubject: saveCompletedSubject)
            }
            .store(in: &cancellables)

        return Output(
            profile: profileSubject.eraseToAnyPublisher(),
            saveCompleted: saveCompletedSubject.eraseToAnyPublisher()
        )
    }

    private func save(draft: MyPageEditDraft, saveCompletedSubject: PassthroughSubject<UserProfile, Never>) {
        let trimmedNick = draft.nick.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNick.isEmpty else {
            error.send(DomainError.validation(message: "닉네임은 빈 값일 수 없습니다."))
            return
        }
        guard isValidNick(trimmedNick) else {
            error.send(DomainError.validation(message: "닉네임에 사용할 수 없는 문자가 포함되어 있습니다."))
            return
        }

        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let intro = draft.introduction.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = draft.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let hashTags = parseHashTags(from: draft.hashTagsText)

        let update = UserProfileUpdate(
            nick: trimmedNick,
            name: name.isEmpty ? nil : name,
            introduction: intro.isEmpty ? nil : intro,
            description: nil,
            phoneNumber: phone.isEmpty ? nil : phone,
            profileImageURL: draft.profileImageURL,
            hashTags: hashTags
        )

        isLoading.send(true)
        userRepository.updateMyProfile(update)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { profile in
                saveCompletedSubject.send(profile)
            }
            .store(in: &cancellables)
    }

    private func parseHashTags(from text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ", ")
        let raw = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return raw
    }

    private func isValidNick(_ nick: String) -> Bool {
        let forbidden = CharacterSet(charactersIn: ".,?*+-@^${}()|[]\\")
        return nick.rangeOfCharacter(from: forbidden) == nil
    }
}

extension MyPageEditViewModel {
    func makeImageUploadViewModel() -> MyPageImageUploadViewModel {
        MyPageImageUploadViewModel(userRepository: userRepository)
    }
}
