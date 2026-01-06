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
    private var currentRoomID: String?

    var onMessage: ((ChatMessageDTO) -> Void)?

    init(baseURL: URL, namespace: String, tokenProvider: @escaping () -> String?) {
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
        socket = manager.socket(forNamespace: namespace)

        socket.on(clientEvent: .connect) { _, _ in
            #if DEBUG
            print("[ChatSocket] connected")
            #endif
            if let roomID = self.currentRoomID {
                self.emitJoin(roomID: roomID)
            }
        }
        socket.on(clientEvent: .disconnect) { data, _ in
            #if DEBUG
            print("[ChatSocket] disconnected \(data)")
            #endif
        }
        socket.on(clientEvent: .error) { data, _ in
            #if DEBUG
            print("[ChatSocket] error \(data)")
            #endif
        }
        #if DEBUG
        socket.onAny { event in
            print("[ChatSocket] event \(event.event) items=\(event.items ?? [])")
        }
        #endif
        socket.on("chat") { [weak self] data, _ in
            guard let payload = data.first else { return }
            if let dto = self?.decodeMessage(from: payload) {
                self?.onMessage?(dto)
            }
        }
    }

    func connect() {
        #if DEBUG
        print("[ChatSocket] connect()")
        #endif
        socket.connect()
    }

    func disconnect() {
        #if DEBUG
        print("[ChatSocket] disconnect()")
        #endif
        socket.disconnect()
    }

    func shutdown() {
        currentRoomID = nil
        #if DEBUG
        print("[ChatSocket] shutdown()")
        #endif
        manager.reconnects = false
        socket.removeAllHandlers()
        socket.disconnect()
        manager.disconnect()
    }

    func join(roomID: String) {
        currentRoomID = roomID
        emitJoin(roomID: roomID)
    }

    func send(roomID: String, content: String) {
        #if DEBUG
        print("[ChatSocket] send room=\(roomID)")
        #endif
        socket.emit("send", ["room_id": roomID, "content": content])
    }

    private func emitJoin(roomID: String) {
        guard socket.status == .connected else { return }
        #if DEBUG
        print("[ChatSocket] join room=\(roomID)")
        #endif
        socket.emit("join", ["room_id": roomID])
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
