//
//  PersistentRecordStore.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Store — a list-oriented blob persistence port (SwiftData-backed).
//

import Foundation

/// A persistence capability for lists of records, keyed by `(kind, id)` and stored as
/// opaque `Data` blobs — declared in Infrastructure, like ``KeyValueStore``, so the
/// Data layer can persist domain values without knowing the backing store is SwiftData.
///
/// `kind` namespaces record types (e.g. "rankedJob", later "applicationKit",
/// "applicationStatus"), so one store serves several repositories. Keeping the port in
/// terms of `String`/`Data` keeps SwiftData's `@Model` types fully inside Infrastructure.
protocol PersistentRecordStore: Sendable {
    /// Inserts or replaces the blob for `(kind, id)`.
    func upsert(kind: String, id: String, data: Data) async throws
    /// All blobs of `kind`, in no guaranteed order.
    func records(ofKind kind: String) async throws -> [Data]
    /// The blob for `(kind, id)`, or `nil` if absent.
    func record(ofKind kind: String, id: String) async throws -> Data?
    /// Removes the record for `(kind, id)` if present.
    func delete(kind: String, id: String) async throws
}
