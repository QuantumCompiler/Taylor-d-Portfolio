//
//  SettingsStore.swift
//  Taylor'd Portfolio
//
//  Data · Settings — loads and saves AppSettings via a KeyValueStore.
//

import Foundation

/// Loads and saves ``AppSettings`` through a `KeyValueStore`.
///
/// `load()` returns `.default` when nothing is stored or the stored blob can't be
/// decoded, so the app always has usable settings.
nonisolated struct SettingsStore {
    private static let key = "com.veritum.taylordportfolio.appSettings"

    let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    /// The current settings, or `.default` when absent/corrupt.
    func load() -> AppSettings {
        guard
            let data = store.data(forKey: Self.key),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    /// Persists `settings`.
    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        store.setData(data, forKey: Self.key)
    }
}
