//
//  ChatAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum ChatAPI: APIEndpoint {
    case createRoom(body: any Encodable)
    case fetchRooms
    case sendMessage(roomID: String, body: any Encodable)
    case fetchMessages(roomID: String, next: String?)
    case uploadFiles(roomID: String, files: [UploadFile])

    var path: String {
        switch self {
        case .createRoom, .fetchRooms:
            return "v1/chats"
        case .sendMessage(let roomID, _), .fetchMessages(let roomID, _):
            return "v1/chats/\(roomID)"
        case .uploadFiles(let roomID, _):
            return "v1/chats/\(roomID)/files"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createRoom, .sendMessage, .uploadFiles:
            return .post
        case .fetchRooms, .fetchMessages:
            return .get
        }
    }

    var task: APITask {
        switch self {
        case .createRoom(let body), .sendMessage(_, let body):
            return .requestJSON(body)
        case .fetchRooms:
            return .requestPlain
        case .fetchMessages(_, let next):
            return .requestQuery(compactQuery([
                "next": next
            ]))
        case .uploadFiles(_, let files):
            return .uploadFiles(files)
        }
    }

    var requiresAuth: Bool { true }
}
