//
//  UserDefaultsStore.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Store — KeyValueStore backed by UserDefaults.
//

import Foundation

/// The production `KeyValueStore`, backed by `UserDefaults`.
///
/// Suitable for non-secret app settings. A keychain-backed store can be swapped in
/// behind the same port for secrets if needed later.
nonisolated struct UserDefaultsStore: KeyValueStore {
    // UserDefaults is thread-safe but not marked Sendable; this is safe to share.
    nonisolated(unsafe) let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func setData(_ data: Data?, forKey key: String) {
        if let data {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
