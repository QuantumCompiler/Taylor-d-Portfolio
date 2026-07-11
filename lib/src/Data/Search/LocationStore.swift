//
//  LocationStore.swift
//  Taylor'd Portfolio
//
//  Data · Search — persists the user's saved search locations.
//

import Foundation

/// Persists the user's custom search locations through a `KeyValueStore`, so a location
/// they type and save on the Search screen survives across launches and joins the preset
/// suggestions. Mirrors ``RoleTitleStore``; `load()` returns `[]` when absent or corrupt.
nonisolated struct LocationStore {
    private static let key = "com.veritum.taylordportfolio.savedLocations"

    let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    func load() -> [String] {
        guard
            let data = store.data(forKey: Self.key),
            let values = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }
        return values
    }

    func save(_ locations: [String]) {
        guard let data = try? JSONEncoder().encode(locations) else { return }
        store.setData(data, forKey: Self.key)
    }
}
