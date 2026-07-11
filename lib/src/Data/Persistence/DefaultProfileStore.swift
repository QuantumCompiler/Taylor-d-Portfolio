//
//  DefaultProfileStore.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — remembers which saved profile is the user's default.
//

import Foundation

/// Persists the id of the user's **default** saved profile through a `KeyValueStore`,
/// so it can be auto-loaded on launch. A single scalar pointer (mirrors ``RoleTitleStore``)
/// rather than an `isDefault` flag on each profile — that keeps "exactly one default"
/// true by construction. `load()` returns `nil` when nothing is stored or it can't decode.
nonisolated struct DefaultProfileStore {
    private static let key = "com.veritum.taylordportfolio.defaultProfileID"

    let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    /// The default profile's id, or `nil` when none is set.
    func load() -> String? {
        guard
            let data = store.data(forKey: Self.key),
            let id = try? JSONDecoder().decode(String.self, from: data)
        else {
            return nil
        }
        return id
    }

    /// Persists `id` as the default, or clears it when `id` is `nil`.
    func save(_ id: String?) {
        guard let id else {
            store.setData(nil, forKey: Self.key)
            return
        }
        store.setData(try? JSONEncoder().encode(id), forKey: Self.key)
    }
}
