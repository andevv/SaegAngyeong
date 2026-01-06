//
//  ChatSocketClient.swift
//  SaegAngyeong
//
//  Created by andev on 1/6/26.
//

import Foundation
import SocketIO

final class ChatSocketClient {
    private let manager: SocketManager
    private let socket: SocketIOClient

    var onMessage: ((ChatMessageDTO) -> Void)?

    init(baseURL: URL, tokenProvider: @escaping () -> String?) {
        let config: SocketIOClientConfiguration = [
            .compress,
            .log(false),
            .forceWebsockets(true),
            .extraHeaders([
                "SeSACKey": AppConfig.apiKey,
                "Authorization": tokenProvider() ?? ""
            ])
        ]
        manager = SocketManager(socketURL: baseURL, config: config)
        socket = manager.defaultSocket

        socket.on("message") { [weak self] data, _ in
            guard let payload = data.first else { return }
            if let dto = self?.decodeMessage(from: payload) {
                self?.onMessage?(dto)
            }
        }
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    func join(roomID: String) {
        socket.emit("join", ["room_id": roomID])
    }

    func send(roomID: String, content: String) {
        socket.emit("send", ["room_id": roomID, "content": content])
    }

    private func decodeMessage(from payload: Any) -> ChatMessageDTO? {
        if let dict = payload as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            return try? JSONDecoder().decode(ChatMessageDTO.self, from: data)
        }
        if let string = payload as? String,
           let data = string.data(using: .utf8) {
            return try? JSONDecoder().decode(ChatMessageDTO.self, from: data)
        }
        return nil
    }
}
