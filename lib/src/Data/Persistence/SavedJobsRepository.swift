//
//  SavedJobsRepository.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — persists pulled listings + their match results.
//

import Foundation

/// Persists the ranked jobs a search (or a fetched link) pulls down, mapping the clean
/// domain ``RankedJob`` to/from the Infrastructure ``PersistentRecordStore``'s blobs.
///
/// Keyed by `JobListing.id` (upsert), so re-pulling a posting updates rather than
/// duplicates it. The store's `@Model` type stays in Infrastructure — this gateway is
/// the only place that knows a `RankedJob` is encoded to `Data` for storage.
nonisolated struct SavedJobsRepository: Sendable {
    static let kind = "rankedJob"

    let store: any PersistentRecordStore

    init(store: any PersistentRecordStore) {
        self.store = store
    }

    /// Upserts each ranked job by its listing id.
    func save(_ jobs: [RankedJob]) async throws {
        let encoder = JSONEncoder()
        for job in jobs {
            let data = try encoder.encode(job)
            try await store.upsert(kind: Self.kind, id: job.id, data: data)
        }
    }

    /// All saved ranked jobs, decoded to domain values (best-effort: undecodable rows
    /// are skipped), sorted by score descending like a fresh ranking.
    func savedJobs() async throws -> [RankedJob] {
        let decoder = JSONDecoder()
        let blobs = try await store.records(ofKind: Self.kind)
        return blobs
            .compactMap { try? decoder.decode(RankedJob.self, from: $0) }
            .sorted { $0.score > $1.score }
    }

    /// Whether a listing with `jobID` has already been saved ("already seen").
    func contains(jobID: String) async throws -> Bool {
        try await store.record(ofKind: Self.kind, id: jobID) != nil
    }
}
