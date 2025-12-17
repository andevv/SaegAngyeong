//
//  RepositoryProtocols.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Combine

// MARK: - Auth

protocol AuthRepository {
    func login(email: String, password: String, deviceToken: String?) -> AnyPublisher<AuthSession, DomainError>
    func loginKakao(oauthToken: String, deviceToken: String?) -> AnyPublisher<AuthSession, DomainError>
    func loginApple(idToken: String, deviceToken: String?) -> AnyPublisher<AuthSession, DomainError>
    func join(email: String, password: String, nick: String, name: String?, introduction: String?, phone: String?, hashTags: [String], deviceToken: String?) -> AnyPublisher<AuthSession, DomainError>
    func refresh(refreshToken: String) -> AnyPublisher<AuthTokens, DomainError>
    func logout() -> AnyPublisher<Void, DomainError>
    func updateDeviceToken(_ token: String) -> AnyPublisher<Void, DomainError>
}

// MARK: - User

protocol UserRepository {
    func validateEmail(_ email: String) -> AnyPublisher<Void, DomainError>
    func fetchProfile(userID: String) -> AnyPublisher<UserProfile, DomainError>
    func fetchMyProfile() -> AnyPublisher<UserProfile, DomainError>
    func updateMyProfile(_ profile: UserProfileUpdate) -> AnyPublisher<UserProfile, DomainError>
    func uploadProfileImage(data: Data, fileName: String, mimeType: String) -> AnyPublisher<URL, DomainError>
    func search(nick: String?) -> AnyPublisher<[UserSummary], DomainError>
    func todayAuthor() -> AnyPublisher<TodayAuthor, DomainError>
}

// MARK: - Filter

protocol FilterRepository {
    func uploadFiles(_ files: [UploadFileData]) -> AnyPublisher<[URL], DomainError>
    func create(_ draft: FilterDraft) -> AnyPublisher<Filter, DomainError>
    func list(next: String?, limit: Int?, category: String?, orderBy: String?) -> AnyPublisher<Paginated<Filter>, DomainError>
    func detail(id: String) -> AnyPublisher<Filter, DomainError>
    func update(id: String, draft: FilterDraft) -> AnyPublisher<Filter, DomainError>
    func delete(id: String) -> AnyPublisher<Void, DomainError>
    func like(id: String, status: Bool) -> AnyPublisher<Void, DomainError>
    func userFilters(userID: String, next: String?, limit: Int?, category: String?) -> AnyPublisher<Paginated<Filter>, DomainError>
    func likedFilters(category: String?, next: String?, limit: Int?) -> AnyPublisher<Paginated<Filter>, DomainError>
    func hotTrend() -> AnyPublisher<[Filter], DomainError>
    func todayFilter() -> AnyPublisher<Filter, DomainError>
    func addComment(filterID: String, draft: CommentDraft) -> AnyPublisher<Comment, DomainError>
    func updateComment(filterID: String, commentID: String, content: String) -> AnyPublisher<Comment, DomainError>
    func deleteComment(filterID: String, commentID: String) -> AnyPublisher<Void, DomainError>
}

// MARK: - Post

protocol PostRepository {
    func uploadFiles(_ files: [UploadFileData]) -> AnyPublisher<[URL], DomainError>
    func create(_ draft: PostDraft) -> AnyPublisher<Post, DomainError>
    func list(next: String?, limit: Int?, category: String?) -> AnyPublisher<Paginated<Post>, DomainError>
    func detail(id: String) -> AnyPublisher<Post, DomainError>
    func update(id: String, draft: PostDraft) -> AnyPublisher<Post, DomainError>
    func delete(id: String) -> AnyPublisher<Void, DomainError>
    func like(id: String, status: Bool) -> AnyPublisher<Void, DomainError>
    func search(title: String?) -> AnyPublisher<[Post], DomainError>
    func geolocation(category: String?, lon: Double?, lat: Double?, maxDistance: Double?, limit: Int?, next: String?, orderBy: String?) -> AnyPublisher<Paginated<Post>, DomainError>
    func userPosts(userID: String, category: String?, limit: Int?, next: String?) -> AnyPublisher<Paginated<Post>, DomainError>
    func likedPosts(category: String?, next: String?, limit: Int?) -> AnyPublisher<Paginated<Post>, DomainError>
    func addComment(postID: String, draft: CommentDraft) -> AnyPublisher<Comment, DomainError>
    func updateComment(postID: String, commentID: String, content: String) -> AnyPublisher<Comment, DomainError>
    func deleteComment(postID: String, commentID: String) -> AnyPublisher<Void, DomainError>
}

// MARK: - Chat

protocol ChatRepository {
    func createRoom(name: String?) -> AnyPublisher<ChatRoom, DomainError>
    func fetchRooms() -> AnyPublisher<[ChatRoom], DomainError>
    func sendMessage(roomID: String, draft: ChatMessageDraft) -> AnyPublisher<ChatMessage, DomainError>
    func fetchMessages(roomID: String, next: String?) -> AnyPublisher<Paginated<ChatMessage>, DomainError>
    func uploadFiles(roomID: String, files: [UploadFileData]) -> AnyPublisher<[URL], DomainError>
}

// MARK: - Video

protocol VideoRepository {
    func list(next: String?, limit: Int?) -> AnyPublisher<Paginated<Video>, DomainError>
    func streamInfo(videoID: String) -> AnyPublisher<StreamInfo, DomainError>
    func like(videoID: String, status: Bool) -> AnyPublisher<Void, DomainError>
}

// MARK: - Order & Payment

protocol OrderRepository {
    func create(filterID: String, totalPrice: Int) -> AnyPublisher<Order, DomainError>
    func list() -> AnyPublisher<[Order], DomainError>
    func paymentDetail(orderCode: String) -> AnyPublisher<Order, DomainError>
}

protocol PaymentRepository {
    func validatePayment(impUID: String, filterID: String) -> AnyPublisher<Void, DomainError>
}

// MARK: - Banner & Log & Notification

protocol BannerRepository {
    func mainBanners() -> AnyPublisher<[Banner], DomainError>
}

protocol LogRepository {
    func fetchLog() -> AnyPublisher<Void, DomainError>
}

protocol NotificationRepository {
    func push(title: String, body: String, targetUserIDs: [String]) -> AnyPublisher<Void, DomainError>
}

// MARK: - Upload helper

struct UploadFileData {
    let data: Data
    let fileName: String
    let mimeType: String
}
