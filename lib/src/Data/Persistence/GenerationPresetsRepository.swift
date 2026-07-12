//
//  GenerationPresetsRepository.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — persists the user's saved generation presets (Milestone D-D).
//

import Foundation

/// Persists the user's library of ``GenerationPreset``s, mapping the clean domain value
/// to/from the Infrastructure ``PersistentRecordStore``'s blobs. Mirrors
/// ``SavedSearchesRepository``.
///
/// Keyed by `GenerationPreset.id` (upsert), so re-saving under the same id updates rather
/// than duplicates. The `@Model` backing type stays in Infrastructure.
nonisolated struct GenerationPresetsRepository: Sendable {
    static let kind = "generationPreset"

    let store: any PersistentRecordStore

    init(store: any PersistentRecordStore) {
        self.store = store
    }

    /// Inserts or replaces `preset` by its id.
    func save(_ preset: GenerationPreset) async throws {
        let data = try JSONEncoder().encode(preset)
        try await store.upsert(kind: Self.kind, id: preset.id, data: data)
    }

    /// All saved presets, decoded to domain values (undecodable rows skipped), newest first.
    func all() async throws -> [GenerationPreset] {
        let decoder = JSONDecoder()
        let blobs = try await store.records(ofKind: Self.kind)
        return blobs
            .compactMap { try? decoder.decode(GenerationPreset.self, from: $0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Removes the preset with `id` if present.
    func delete(id: String) async throws {
        try await store.delete(kind: Self.kind, id: id)
    }
}
