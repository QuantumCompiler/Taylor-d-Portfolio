//
//  SavedProfilesRepository.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — persists named CandidateProfiles the user has saved.
//

import Foundation

/// Persists the user's library of named ``SavedProfile``s, mapping the clean domain
/// value to/from the Infrastructure ``PersistentRecordStore``'s blobs.
///
/// Keyed by `SavedProfile.id` (upsert), so re-saving under the same id renames/updates
/// rather than duplicates. The `@Model` backing type stays in Infrastructure — this
/// gateway is the only place that knows a `SavedProfile` is encoded to `Data`.
nonisolated struct SavedProfilesRepository: Sendable {
    static let kind = "candidateProfile"

    let store: any PersistentRecordStore

    init(store: any PersistentRecordStore) {
        self.store = store
    }

    /// Inserts or replaces `saved` by its id.
    func save(_ saved: SavedProfile) async throws {
        let data = try JSONEncoder().encode(saved)
        try await store.upsert(kind: Self.kind, id: saved.id, data: data)
    }

    /// All saved profiles, decoded to domain values (best-effort: undecodable rows are
    /// skipped), newest first.
    func all() async throws -> [SavedProfile] {
        let decoder = JSONDecoder()
        let blobs = try await store.records(ofKind: Self.kind)
        return blobs
            .compactMap { try? decoder.decode(SavedProfile.self, from: $0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Removes the saved profile with `id` if present.
    func delete(id: String) async throws {
        try await store.delete(kind: Self.kind, id: id)
    }
}
