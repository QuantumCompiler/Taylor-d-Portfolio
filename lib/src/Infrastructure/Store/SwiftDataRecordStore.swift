//
//  SwiftDataRecordStore.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Store — SwiftData-backed PersistentRecordStore.
//

import Foundation
import SwiftData

/// The SwiftData row behind ``PersistentRecordStore``. Kept `internal` to
/// Infrastructure so the `@Model` type never leaks upward into Data/Business/
/// Presentation — callers only ever see `Data` blobs.
@Model
final class StoredRecord {
    /// Composite unique key ("kind\u{1}id") so upsert can find an existing row.
    @Attribute(.unique) var key: String
    var kind: String
    var recordID: String
    var data: Data

    init(kind: String, recordID: String, data: Data) {
        self.kind = kind
        self.recordID = recordID
        self.data = data
        self.key = Self.makeKey(kind: kind, recordID: recordID)
    }

    static func makeKey(kind: String, recordID: String) -> String { "\(kind)\u{1}\(recordID)" }
}

/// A `PersistentRecordStore` backed by SwiftData. `@ModelActor` gives it its own
/// `ModelContext` bound to a private actor, so persistence runs safely off the main
/// actor and the type is `Sendable`.
@ModelActor
actor SwiftDataRecordStore: PersistentRecordStore {

    func upsert(kind: String, id: String, data: Data) throws {
        let key = StoredRecord.makeKey(kind: kind, recordID: id)
        let descriptor = FetchDescriptor<StoredRecord>(predicate: #Predicate { $0.key == key })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.data = data
        } else {
            modelContext.insert(StoredRecord(kind: kind, recordID: id, data: data))
        }
        try modelContext.save()
    }

    func records(ofKind kind: String) throws -> [Data] {
        let descriptor = FetchDescriptor<StoredRecord>(predicate: #Predicate { $0.kind == kind })
        return try modelContext.fetch(descriptor).map(\.data)
    }

    func record(ofKind kind: String, id: String) throws -> Data? {
        let key = StoredRecord.makeKey(kind: kind, recordID: id)
        let descriptor = FetchDescriptor<StoredRecord>(predicate: #Predicate { $0.key == key })
        return try modelContext.fetch(descriptor).first?.data
    }

    func delete(kind: String, id: String) throws {
        let key = StoredRecord.makeKey(kind: kind, recordID: id)
        let descriptor = FetchDescriptor<StoredRecord>(predicate: #Predicate { $0.key == key })
        for record in try modelContext.fetch(descriptor) {
            modelContext.delete(record)
        }
        try modelContext.save()
    }
}
