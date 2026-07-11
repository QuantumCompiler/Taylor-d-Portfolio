//
//  RoleTitleStore.swift
//  Taylor'd Portfolio
//
//  Data · Search — persists the user's curated "common role titles".
//

import Foundation

/// Persists the user's curated list of common role titles through a `KeyValueStore`,
/// so the titles they save (by long-pressing a chip on the Search screen) survive
/// across launches.
///
/// A small standalone store (mirrors ``SettingsStore``) rather than part of
/// `AppSettings`, since it's a growing vocabulary rather than a discrete preference.
/// `load()` returns an empty list when nothing is stored or the blob can't decode.
nonisolated struct RoleTitleStore {
    private static let key = "com.veritum.taylordportfolio.commonRoleTitles"

    let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    /// The saved common role titles, or `[]` when absent/corrupt.
    func load() -> [String] {
        guard
            let data = store.data(forKey: Self.key),
            let titles = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }
        return titles
    }

    /// Persists `titles`.
    func save(_ titles: [String]) {
        guard let data = try? JSONEncoder().encode(titles) else { return }
        store.setData(data, forKey: Self.key)
    }
}
