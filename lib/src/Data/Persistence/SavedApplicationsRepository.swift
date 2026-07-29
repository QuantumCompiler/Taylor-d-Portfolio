//
//  SavedApplicationsRepository.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — persists generated ApplicationKits, keyed by JobListing.id.
//

import Foundation

/// Persists a generated ``ApplicationKit`` — and the ``TargetBrief`` it was generated
/// against — linked to its `JobListing.id`, so the résumé + cover letter a user generates
/// for a posting survive relaunch and can be reopened without a redundant LLM call.
///
/// Reuses the Infrastructure ``PersistentRecordStore`` under a distinct `kind`, keyed
/// by job id (latest-wins upsert). `@Model` stays in Infrastructure.
///
/// The brief rides **inside the kit's own record** (v0.6.1 Milestone B) rather than in a
/// sibling store: keyword coverage compares a résumé against the brief that produced it, so
/// pairing them in one latest-wins record makes it impossible for the two to drift apart —
/// and `DeleteSavedJobUseCase` already forgets both in its existing single delete, with no
/// orphan to clean up.
nonisolated struct SavedApplicationsRepository: Sendable {
    static let kind = "applicationKit"

    /// What a record actually holds. Records written before Milestone B are a bare
    /// ``ApplicationKit``, so reads try this envelope first and fall back (see ``kit(forJobID:)``).
    private struct StoredApplication: Codable {
        let kit: ApplicationKit
        let brief: TargetBrief?
    }

    let store: any PersistentRecordStore

    init(store: any PersistentRecordStore) {
        self.store = store
    }

    /// Upserts the kit — and the brief it was tailored against — for `jobID` (latest
    /// generation wins). `brief` is optional so callers that have none still persist the kit.
    func save(_ kit: ApplicationKit, brief: TargetBrief? = nil, forJobID jobID: String) async throws {
        let data = try JSONEncoder().encode(StoredApplication(kit: kit, brief: brief))
        try await store.upsert(kind: Self.kind, id: jobID, data: data)
    }

    /// The saved kit for `jobID`, or `nil` if none (or it can't be decoded). Reads records
    /// written before the brief was paired in, by falling back to the bare-kit encoding.
    func kit(forJobID jobID: String) async throws -> ApplicationKit? {
        guard let data = try await store.record(ofKind: Self.kind, id: jobID) else { return nil }
        if let stored = try? JSONDecoder().decode(StoredApplication.self, from: data) { return stored.kit }
        return try? JSONDecoder().decode(ApplicationKit.self, from: data)
    }

    /// The ``TargetBrief`` the saved kit was generated against, or `nil` when the record
    /// predates Milestone B (a legacy bare-kit blob) — so a reopened result can report
    /// keyword coverage where the brief is known, and simply omit it where it isn't.
    func brief(forJobID jobID: String) async throws -> TargetBrief? {
        guard let data = try await store.record(ofKind: Self.kind, id: jobID) else { return nil }
        return (try? JSONDecoder().decode(StoredApplication.self, from: data))?.brief
    }

    /// The ids of every job that has a generated kit ("already generated") — feeds the
    /// cross-screen history story (Milestone S-C).
    func savedJobIDs() async throws -> Set<String> {
        Set(try await store.entries(ofKind: Self.kind).map(\.id))
    }

    /// Removes the saved kit for `jobID` if present (Milestone V-A).
    func delete(jobID: String) async throws {
        try await store.delete(kind: Self.kind, id: jobID)
    }
}
