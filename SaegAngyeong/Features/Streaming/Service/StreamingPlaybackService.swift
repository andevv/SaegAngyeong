//
//  StreamingPlaybackService.swift
//  SaegAngyeong
//
//  Created by andev on 1/14/26.
//

import Foundation
import AVFoundation

final class StreamingPlaybackService {
    let player = AVPlayer()
    private var resourceLoader: StreamingResourceLoader?
    private(set) var currentVideoID: String?
    private var currentURL: URL?
    var currentTitle: String? {
        didSet {
            if currentTitle != oldValue {
                onTitleChanged?(currentTitle)
            }
        }
    }
    var currentViewCountText: String?
    var currentLikeCountText: String?
    var onTitleChanged: ((String?) -> Void)?

    func prepare(
        videoID: String,
        url: URL,
        headersProvider: @escaping () -> [String: String]
    ) -> AVPlayerItem {
        if currentVideoID == videoID, let item = player.currentItem {
            currentVideoID = videoID
            return item
        }
        if let currentURL, currentURL == url, let item = player.currentItem {
            currentVideoID = videoID
            return item
        }

        currentVideoID = videoID
        currentURL = url

        let assetOptions: [String: Any] = [
            AVURLAssetAllowsCellularAccessKey: true
        ]
        let loader = StreamingResourceLoader(
            originalScheme: url.scheme ?? "http",
            disableSubtitles: true,
            headersProvider: headersProvider
        )
        resourceLoader = loader
        let assetURL = StreamingResourceLoader.makeCustomSchemeURL(from: url) ?? url
        let asset = AVURLAsset(url: assetURL, options: assetOptions)
        asset.resourceLoader.setDelegate(loader, queue: DispatchQueue(label: "streaming.resource.loader"))
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        return item
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        resourceLoader = nil
        currentURL = nil
        currentVideoID = nil
        currentTitle = nil
        currentViewCountText = nil
        currentLikeCountText = nil
    }
}
