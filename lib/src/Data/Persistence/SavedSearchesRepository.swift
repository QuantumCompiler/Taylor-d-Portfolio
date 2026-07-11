//
//  SavedSearchesRepository.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — persists the user's saved searches.
//

import Foundation

/// Persists the user's library of ``SavedSearch``es, mapping the clean domain value
/// to/from the Infrastructure ``PersistentRecordStore``'s blobs (ROADMAP Milestone R).
///
/// Keyed by `SavedSearch.id` (upsert), so re-saving under the same id updates rather than
/// duplicates. The `@Model` backing type stays in Infrastructure — this gateway is the only
/// place that knows a `SavedSearch` is encoded to `Data`.
nonisolated struct SavedSearchesRepository: Sendable {
    static let kind = "savedSearch"

    let store: any PersistentRecordStore

    init(store: any PersistentRecordStore) {
        self.store = store
    }

    /// Inserts or replaces `saved` by its id.
    func save(_ saved: SavedSearch) async throws {
        let data = try JSONEncoder().encode(saved)
        try await store.upsert(kind: Self.kind, id: saved.id, data: data)
    }

    /// All saved searches, decoded to domain values (undecodable rows skipped), newest first.
    func all() async throws -> [SavedSearch] {
        let decoder = JSONDecoder()
        let blobs = try await store.records(ofKind: Self.kind)
        return blobs
            .compactMap { try? decoder.decode(SavedSearch.self, from: $0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Removes the saved search with `id` if present.
    func delete(id: String) async throws {
        try await store.delete(kind: Self.kind, id: id)
    }
}
