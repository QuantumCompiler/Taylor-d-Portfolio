//
//  SavedApplicationsRepository.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — persists generated ApplicationKits, keyed by JobListing.id.
//

import Foundation

/// Persists a generated ``ApplicationKit`` linked to its `JobListing.id`, so the
/// résumé + cover letter a user generates for a posting survive relaunch and can be
/// reopened without a redundant LLM call.
///
/// Reuses the Infrastructure ``PersistentRecordStore`` under a distinct `kind`, keyed
/// by job id (latest-wins upsert). `@Model` stays in Infrastructure.
nonisolated struct SavedApplicationsRepository: Sendable {
    static let kind = "applicationKit"

    let store: any PersistentRecordStore

    init(store: any PersistentRecordStore) {
        self.store = store
    }

    /// Upserts the kit for `jobID` (latest generation wins).
    func save(_ kit: ApplicationKit, forJobID jobID: String) async throws {
        let data = try JSONEncoder().encode(kit)
        try await store.upsert(kind: Self.kind, id: jobID, data: data)
    }

    /// The saved kit for `jobID`, or `nil` if none (or it can't be decoded).
    func kit(forJobID jobID: String) async throws -> ApplicationKit? {
        guard let data = try await store.record(ofKind: Self.kind, id: jobID) else { return nil }
        return try? JSONDecoder().decode(ApplicationKit.self, from: data)
    }
}
