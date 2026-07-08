//
//  KeyValueStore.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Store — a small key/value persistence port.
//

import Foundation

/// A minimal blob-by-key persistence capability, declared in Infrastructure so the
/// Data layer can persist settings without knowing whether the backing store is
/// `UserDefaults`, the keychain, or an in-memory stub.
protocol KeyValueStore: Sendable {
    /// Returns the data stored for `key`, or `nil` if absent.
    nonisolated func data(forKey key: String) -> Data?
    /// Stores `data` for `key`, or removes the entry when `data` is `nil`.
    nonisolated func setData(_ data: Data?, forKey key: String)
}
