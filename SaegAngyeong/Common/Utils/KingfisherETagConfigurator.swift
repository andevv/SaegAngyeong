//
//  KingfisherETagConfigurator.swift
//  SaegAngyeong
//
//  Created by andev on 12/17/25.
//

import Foundation
import Kingfisher

enum KingfisherETagConfigurator {
    private static var sharedDelegate: ETagImageDownloaderDelegate?

    static func configure(store: ETagStore) {
        let config = URLSessionConfiguration.default
        // 기본 URLCache 사용 (ETag 304를 활용)
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )

        let modifier = AnyModifier { request in
            var r = request
            if let url = r.url, let etag = store.eTag(for: url) {
                r.setValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            return r
        }

        let downloader = ImageDownloader(name: "etag.downloader")
        downloader.sessionConfiguration = config
        let delegate = ETagImageDownloaderDelegate(store: store)
        downloader.delegate = delegate
        sharedDelegate = delegate

        KingfisherManager.shared.downloader = downloader
        KingfisherManager.shared.defaultOptions = [.requestModifier(modifier)]
    }
}

private final class ETagImageDownloaderDelegate: ImageDownloaderDelegate {
    private let store: ETagStore

    init(store: ETagStore) {
        self.store = store
    }

    func imageDownloader(_ downloader: ImageDownloader, didFinishDownloadingImageForURL url: URL?, with response: URLResponse?) {
        guard
            let url,
            let http = response as? HTTPURLResponse,
            let etag = http.allHeaderFields["Etag"] as? String ?? http.allHeaderFields["ETag"] as? String
        else { return }
        store.save(eTag: etag, for: url)
    }
}
