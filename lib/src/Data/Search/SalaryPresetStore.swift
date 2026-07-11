//
//  SalaryPresetStore.swift
//  Taylor'd Portfolio
//
//  Data · Search — persists the user's saved minimum-salary presets.
//

import Foundation

/// Persists the user's custom minimum-salary floors through a `KeyValueStore`, so a salary
/// they type and save on the Search screen survives across launches and joins the built-in
/// preset brackets. Mirrors ``RoleTitleStore``; `load()` returns `[]` when absent or corrupt.
nonisolated struct SalaryPresetStore {
    private static let key = "com.veritum.taylordportfolio.savedSalaryPresets"

    let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    func load() -> [Int] {
        guard
            let data = store.data(forKey: Self.key),
            let values = try? JSONDecoder().decode([Int].self, from: data)
        else {
            return []
        }
        return values
    }

    func save(_ salaries: [Int]) {
        guard let data = try? JSONEncoder().encode(salaries) else { return }
        store.setData(data, forKey: Self.key)
    }
}
