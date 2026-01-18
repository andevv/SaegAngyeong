//
//  NetworkStatusMonitor.swift
//  SaegAngyeong
//
//  Created by andev on 1/18/26.
//

import Network
import Foundation

final class NetworkStatusMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.saegangyeong.networkmonitor")
    private var isRunning = false
    private var lastStatus: NWPath.Status?

    private(set) var currentStatus: NWPath.Status = .requiresConnection
    var onStatusChange: ((NWPath.Status) -> Void)?

    func start() {
        guard isRunning == false else { return }
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let status = path.status
            guard status != self.lastStatus else { return }
            self.lastStatus = status
            self.currentStatus = status
            DispatchQueue.main.async {
                self.onStatusChange?(status)
            }
        }
        monitor.start(queue: queue)
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        monitor.cancel()
        isRunning = false
    }
}
