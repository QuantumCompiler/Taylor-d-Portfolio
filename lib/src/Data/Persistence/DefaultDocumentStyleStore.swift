//
//  DefaultDocumentStyleStore.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — remembers which saved style is the user's default (v0.7.0 Milestone D).
//

import Foundation

/// Persists the id of the user's **default** ``SavedDocumentStyle`` through a `KeyValueStore`, so
/// the export picker can preselect it. A single scalar pointer (mirrors ``DefaultProfileStore``)
/// rather than an `isDefault` flag per style — that keeps "exactly one default" true by
/// construction instead of an invariant something has to maintain. `load()` returns `nil` when
/// nothing is stored or it can't decode.
nonisolated struct DefaultDocumentStyleStore {
    private static let key = "com.veritum.taylordportfolio.defaultDocumentStyleID"

    let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    /// The default style's id, or `nil` when none is set.
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

    /// The style the pointer names, or `nil` when no default is set **or** the style it named is
    /// gone — the caller then falls back to the built-in template default.
    ///
    /// The one deliberate departure from ``DefaultProfileStore``, whose call site resolves a
    /// dangling pointer with `?? profiles.first`: for a profile, any grounding beats none. A style
    /// must not degrade that way — silently applying a style the user never chose changes the
    /// document they're about to send.
    func resolved(in styles: [SavedDocumentStyle]) -> SavedDocumentStyle? {
        guard let id = load() else { return nil }
        return styles.first { $0.id == id }
    }
}
