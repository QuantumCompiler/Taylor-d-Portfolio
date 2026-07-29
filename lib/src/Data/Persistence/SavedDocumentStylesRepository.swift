//
//  SavedDocumentStylesRepository.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — persists the user's saved LaTeX document styles (v0.7.0 Milestone D).
//

import Foundation

/// Persists the user's library of ``SavedDocumentStyle``s, mapping the clean domain value
/// to/from the Infrastructure ``PersistentRecordStore``'s blobs. Mirrors
/// ``SavedProfilesRepository``.
///
/// Keyed by `SavedDocumentStyle.id` (upsert), so re-saving under the same id renames/updates
/// rather than duplicates. **User styles only** — the built-in templates live in
/// ``LaTeXTemplateRegistry`` and are never written here.
nonisolated struct SavedDocumentStylesRepository: Sendable {
    static let kind = "documentStyle"

    let store: any PersistentRecordStore

    init(store: any PersistentRecordStore) {
        self.store = store
    }

    /// Inserts or replaces `saved` by its id.
    func save(_ saved: SavedDocumentStyle) async throws {
        let data = try JSONEncoder().encode(saved)
        try await store.upsert(kind: Self.kind, id: saved.id, data: data)
    }

    /// All saved styles, decoded to domain values (undecodable rows skipped), newest first.
    func all() async throws -> [SavedDocumentStyle] {
        let decoder = JSONDecoder()
        let blobs = try await store.records(ofKind: Self.kind)
        return blobs
            .compactMap { try? decoder.decode(SavedDocumentStyle.self, from: $0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Removes the style with `id` if present.
    func delete(id: String) async throws {
        try await store.delete(kind: Self.kind, id: id)
    }
}
