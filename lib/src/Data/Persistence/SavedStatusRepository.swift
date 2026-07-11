//
//  SavedStatusRepository.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — persists ApplicationStatus, keyed by JobListing.id.
//

import Foundation

/// Persists an ``ApplicationStatus`` per job (by `JobListing.id`), reusing the
/// Infrastructure ``PersistentRecordStore`` under a distinct `kind`. Upsert per job.
nonisolated struct SavedStatusRepository: Sendable {
    static let kind = "applicationStatus"

    let store: any PersistentRecordStore

    init(store: any PersistentRecordStore) {
        self.store = store
    }

    /// Upserts the status for `jobID`.
    func save(_ status: ApplicationStatus, forJobID jobID: String) async throws {
        let data = try JSONEncoder().encode(status)
        try await store.upsert(kind: Self.kind, id: jobID, data: data)
    }

    /// The saved status for `jobID`, or `nil` if the job isn't tracked yet.
    func status(forJobID jobID: String) async throws -> ApplicationStatus? {
        guard let data = try await store.record(ofKind: Self.kind, id: jobID) else { return nil }
        return try? JSONDecoder().decode(ApplicationStatus.self, from: data)
    }

    /// All tracked statuses, keyed by job id (the status blob doesn't carry the id, so
    /// this reads id-bearing entries from the store).
    func allStatuses() async throws -> [String: ApplicationStatus] {
        let decoder = JSONDecoder()
        let entries = try await store.entries(ofKind: Self.kind)
        return Dictionary(
            uniqueKeysWithValues: entries.compactMap { entry in
                (try? decoder.decode(ApplicationStatus.self, from: entry.data)).map { (entry.id, $0) }
            }
        )
    }

    /// Removes the tracked status for `jobID` if present (Milestone V-A).
    func delete(jobID: String) async throws {
        try await store.delete(kind: Self.kind, id: jobID)
    }
}
