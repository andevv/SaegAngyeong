//
//  ChatRoomCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 1/12/26.
//

import UIKit
import QuickLook

final class ChatRoomCoordinator: NSObject, QLPreviewControllerDelegate {
    private let dependency: AppDependency
    private let navigationController: BaseNavigationController
    private var filePreviewDataSource: ChatFilePreviewDataSource?
    private var filePreviewURL: URL?

    init(dependency: AppDependency, navigationController: BaseNavigationController) {
        self.dependency = dependency
        self.navigationController = navigationController
        super.init()
    }

    func bindPreview(to viewController: ChatRoomViewController) {
        viewController.onImagePreview = { [weak self] urls, startIndex in
            self?.showImagePreview(urls: urls, startIndex: startIndex)
        }
        viewController.onFilePreview = { [weak self] url in
            self?.showFilePreview(url: url)
        }
    }

    private func showImagePreview(urls: [URL], startIndex: Int) {
        guard urls.isEmpty == false else { return }
        let previewVC = ChatRoomImagePreviewViewController(
            urls: urls,
            startIndex: startIndex,
            headers: makeImageHeaders()
        )
        previewVC.modalPresentationStyle = .fullScreen
        previewVC.modalTransitionStyle = .crossDissolve
        navigationController.present(previewVC, animated: true)
    }

    private func showFilePreview(url: URL) {
        let headers = makeImageHeaders()
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = headers
        let session = URLSession(configuration: configuration)
        session.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self, let tempURL, error == nil else { return }
            let fileName = response?.suggestedFilename ?? url.lastPathComponent
            let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: destinationURL)
            do {
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            } catch {
                return
            }
            DispatchQueue.main.async {
                let dataSource = ChatFilePreviewDataSource(fileURL: destinationURL)
                let previewController = QLPreviewController()
                previewController.dataSource = dataSource
                previewController.delegate = self
                self.filePreviewDataSource = dataSource
                self.filePreviewURL = destinationURL
                self.navigationController.present(previewController, animated: true)
            }
        }.resume()
    }

    private func makeImageHeaders() -> [String: String] {
        var headers: [String: String] = ["SeSACKey": AppConfig.apiKey]
        if let token = dependency.tokenStore.accessToken {
            headers["Authorization"] = token
        }
        return headers
    }

    deinit {
        #if DEBUG
        AppLogger.debug("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        guard let fileURL = filePreviewURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
        filePreviewURL = nil
        filePreviewDataSource = nil
    }
}

private final class ChatFilePreviewDataSource: NSObject, QLPreviewControllerDataSource {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        fileURL as NSURL
    }
}
