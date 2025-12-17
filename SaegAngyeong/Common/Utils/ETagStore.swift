//
//  ETagStore.swift
//  SaegAngyeong
//
//  Created by andev on 12/17/25.
//

import Foundation

/// Simple ETag persistence backed by UserDefaults
final class ETagStore {
    private let defaults: UserDefaults
    private let key = "com.saegangyeong.cache.etag"
    private let queue = DispatchQueue(label: "com.saegangyeong.cache.etag.queue", attributes: .concurrent)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    nonisolated func eTag(for url: URL) -> String? {
        var result: String?
        queue.sync {
            let map = defaults.dictionary(forKey: key) as? [String: String]
            result = map?[url.absoluteString]
        }
        return result
    }

    func save(eTag: String, for url: URL) {
        queue.async(flags: .barrier) { [defaults, key] in
            var map = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
            map[url.absoluteString] = eTag
            defaults.set(map, forKey: key)
        }
    }

    func remove(for url: URL) {
        queue.async(flags: .barrier) { [defaults, key] in
            var map = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
            map.removeValue(forKey: url.absoluteString)
            defaults.set(map, forKey: key)
        }
    }
}
