//
//  StreamingResourceLoader.swift
//  SaegAngyeong
//
//  Created by andev on 1/9/26.
//

import AVFoundation
import UniformTypeIdentifiers

final class StreamingResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    private let customScheme = "streaming"
    private let originalScheme: String
    private let disableSubtitles: Bool
    private let headersProvider: () -> [String: String]
    private let session: URLSession
    private let lock = NSLock()
    private var tasks: [AVAssetResourceLoadingRequest: URLSessionDataTask] = [:]

    init(originalScheme: String, disableSubtitles: Bool, headersProvider: @escaping () -> [String: String]) {
        self.originalScheme = originalScheme
        self.disableSubtitles = disableSubtitles
        self.headersProvider = headersProvider
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
        super.init()
    }

    static func makeCustomSchemeURL(from url: URL) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "streaming"
        return components?.url
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let url = loadingRequest.request.url,
              let actualURL = mapToOriginalURL(from: url) else {
            loadingRequest.finishLoading(with: NSError(domain: "Streaming", code: -1))
            return false
        }
        #if DEBUG
        print("[StreamingLoader] request: \(actualURL.absoluteString)")
        #endif

        var request = URLRequest(url: actualURL)
        if let dataRequest = loadingRequest.dataRequest {
            let start = dataRequest.requestedOffset
            if dataRequest.requestsAllDataToEndOfResource {
                if start > 0 {
                    request.setValue("bytes=\(start)-", forHTTPHeaderField: "Range")
                }
            } else {
                let end = start + Int64(dataRequest.requestedLength) - 1
                request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
            }
        }

        let headers = headersForRequest(url: actualURL)
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error {
                #if DEBUG
                print("[StreamingLoader] error: \(error.localizedDescription)")
                #endif
                loadingRequest.finishLoading(with: error)
                self?.removeTask(for: loadingRequest)
                return
            }

            let isPlaylist = self?.isPlaylistResponse(response: response, url: actualURL) ?? false
            let isSubtitle = self?.isSubtitleURI(actualURL) ?? false
            var responseData = isPlaylist ? self?.rewritePlaylistIfNeeded(data: data, baseURL: actualURL) : data
            if isSubtitle {
                responseData = self?.sanitizeSubtitleIfNeeded(data: responseData, response: response) ?? responseData
            }
            #if DEBUG
            if let response = response as? HTTPURLResponse {
                print("[StreamingLoader] status: \(response.statusCode) playlist: \(isPlaylist) size: \(responseData?.count ?? 0)")
                if isSubtitle {
                    print("[StreamingLoader] subtitle mime: \(response.mimeType ?? "nil")")
                    if let responseData, let prefix = String(data: responseData.prefix(32), encoding: .utf8) {
                        print("[StreamingLoader] subtitle prefix: \(prefix.replacingOccurrences(of: "\n", with: "\\n"))")
                    }
                }
            }
            #endif

            if let response = response as? HTTPURLResponse,
               let infoRequest = loadingRequest.contentInformationRequest {
                infoRequest.isByteRangeAccessSupported = true
                infoRequest.contentLength = responseData.map { Int64($0.count) } ?? response.expectedContentLength
                if let mimeType = response.mimeType,
                   let uti = UTType(mimeType: mimeType)?.identifier {
                    infoRequest.contentType = uti
                }
            }

            if let responseData, let dataRequest = loadingRequest.dataRequest {
                dataRequest.respond(with: responseData)
            } else if responseData == nil {
                loadingRequest.finishLoading(with: NSError(domain: "Streaming", code: -2))
                self?.removeTask(for: loadingRequest)
                return
            }

            loadingRequest.finishLoading()
            self?.removeTask(for: loadingRequest)
        }

        store(task, for: loadingRequest)
        task.resume()
        return true
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        lock.lock()
        defer { lock.unlock() }
        tasks[loadingRequest]?.cancel()
        tasks[loadingRequest] = nil
    }

    private func mapToOriginalURL(from url: URL) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = originalScheme
        return components?.url
    }

    private func headersForRequest(url: URL) -> [String: String] {
        if url.path.contains("/subtitles") || url.path.hasSuffix(".vtt") {
            return headersProvider()
        }
        if let query = url.query, query.contains("token=") {
            return [:]
        }
        return headersProvider()
    }

    private func isPlaylistResponse(response: URLResponse?, url: URL) -> Bool {
        if let mimeType = response?.mimeType?.lowercased(), mimeType.contains("mpegurl") {
            return true
        }
        return url.pathExtension.lowercased() == "m3u8"
    }

    private func rewritePlaylistIfNeeded(data: Data?, baseURL: URL) -> Data? {
        guard let data,
              var text = String(data: data, encoding: .utf8) else {
            return data
        }

        let baseToken = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "token" })?
            .value

        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var rewritten: [String] = []
        rewritten.reserveCapacity(lines.count)

        for lineSub in lines {
            let line = String(lineSub)
            if disableSubtitles,
               line.hasPrefix("#EXT-X-MEDIA"),
               line.contains("TYPE=SUBTITLES") {
                continue
            }
            if line.hasPrefix("#") {
                let cleaned = disableSubtitles ? removeSubtitlesAttributeIfNeeded(in: line) : line
                rewritten.append(rewriteAttributeURIs(in: cleaned, baseURL: baseURL, token: baseToken) ?? cleaned)
                continue
            }
            guard let resolved = URL(string: line, relativeTo: baseURL)?.absoluteURL,
                  var components = URLComponents(url: resolved, resolvingAgainstBaseURL: false) else {
                rewritten.append(line)
                continue
            }
            components = appendTokenIfNeeded(components, token: baseToken)
            if isPlaylistURI(resolved) {
                components.scheme = customScheme
            }
            rewritten.append(components.url?.absoluteString ?? line)
        }

        text = rewritten.joined(separator: "\n")
        return text.data(using: .utf8)
    }

    private func rewriteAttributeURIs(in line: String, baseURL: URL, token: String?) -> String? {
        guard line.contains("URI=\"") else { return nil }
        let pattern = "URI=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: line.utf16.count)
        var result = line
        let matches = regex.matches(in: line, range: range).reversed()
        for match in matches {
            guard match.numberOfRanges == 2,
                  let uriRange = Range(match.range(at: 1), in: line) else { continue }
            let uriString = String(line[uriRange])
            guard let resolved = URL(string: uriString, relativeTo: baseURL)?.absoluteURL,
                  var components = URLComponents(url: resolved, resolvingAgainstBaseURL: false) else { continue }
            components = appendTokenIfNeeded(components, token: token)
            if isSubtitleURI(resolved) || line.contains("TYPE=SUBTITLES") || isPlaylistURI(resolved) {
                components.scheme = customScheme
            }
            if let replaced = components.url?.absoluteString,
               let replaceRange = Range(match.range(at: 1), in: result) {
                result.replaceSubrange(replaceRange, with: replaced)
            }
        }
        return result
    }

    private func appendTokenIfNeeded(_ components: URLComponents, token: String?) -> URLComponents {
        guard let token, token.isEmpty == false else { return components }
        var updated = components
        var items = updated.queryItems ?? []
        if items.contains(where: { $0.name == "token" }) == false {
            items.append(URLQueryItem(name: "token", value: token))
            updated.queryItems = items
        }
        return updated
    }

    private func removeSubtitlesAttributeIfNeeded(in line: String) -> String {
        guard line.contains("SUBTITLES=") else { return line }
        let pattern = "SUBTITLES=\"[^\"]*\",?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return line }
        let range = NSRange(location: 0, length: line.utf16.count)
        let result = regex.stringByReplacingMatches(in: line, range: range, withTemplate: "")
        return result.replacingOccurrences(of: ",,", with: ",")
    }

    private func isSubtitleURI(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        return path.contains("/subtitles") || path.hasSuffix(".vtt")
    }

    private func isPlaylistURI(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "m3u8"
    }

    private func sanitizeSubtitleIfNeeded(data: Data?, response: URLResponse?) -> Data? {
        guard let data else { return data }
        if let text = String(data: data, encoding: .utf8),
           text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("WEBVTT") {
            return data
        }
        let fallback = "WEBVTT\n\n"
        return fallback.data(using: .utf8) ?? data
    }

    private func store(_ task: URLSessionDataTask, for request: AVAssetResourceLoadingRequest) {
        lock.lock()
        defer { lock.unlock() }
        tasks[request] = task
    }

    private func removeTask(for request: AVAssetResourceLoadingRequest) {
        lock.lock()
        defer { lock.unlock() }
        tasks[request] = nil
    }
}
