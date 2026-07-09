//
//  SwiftDataRecordStoreTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Store — the real SwiftData-backed record store.
//

import Testing
import Foundation
import SwiftData
@testable import Taylor_d_Portfolio

@Suite("SwiftDataRecordStore")
struct SwiftDataRecordStoreTests {

    /// A fresh in-memory store per test.
    private func makeStore() throws -> SwiftDataRecordStore {
        let container = try ModelContainer(
            for: StoredRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataRecordStore(modelContainer: container)
    }

    private func blob(_ s: String) -> Data { Data(s.utf8) }

    @Test func upsertThenFetchByKindAndID() async throws {
        let store = try makeStore()
        try await store.upsert(kind: "job", id: "a", data: blob("A"))
        try await store.upsert(kind: "job", id: "b", data: blob("B"))

        #expect(try await store.record(ofKind: "job", id: "a") == blob("A"))
        #expect(try await store.records(ofKind: "job").count == 2)
        #expect(try await store.record(ofKind: "job", id: "missing") == nil)
    }

    @Test func upsertReplacesExistingByID() async throws {
        let store = try makeStore()
        try await store.upsert(kind: "job", id: "a", data: blob("first"))
        try await store.upsert(kind: "job", id: "a", data: blob("second"))

        #expect(try await store.records(ofKind: "job").count == 1)   // no duplicate
        #expect(try await store.record(ofKind: "job", id: "a") == blob("second"))
    }

    @Test func kindsAreIsolated() async throws {
        let store = try makeStore()
        try await store.upsert(kind: "job", id: "a", data: blob("J"))
        try await store.upsert(kind: "kit", id: "a", data: blob("K"))   // same id, different kind

        #expect(try await store.records(ofKind: "job") == [blob("J")])
        #expect(try await store.records(ofKind: "kit") == [blob("K")])
    }

    @Test func deleteRemovesOnlyThatRecord() async throws {
        let store = try makeStore()
        try await store.upsert(kind: "job", id: "a", data: blob("A"))
        try await store.upsert(kind: "job", id: "b", data: blob("B"))

        try await store.delete(kind: "job", id: "a")
        #expect(try await store.record(ofKind: "job", id: "a") == nil)
        #expect(try await store.record(ofKind: "job", id: "b") == blob("B"))
    }
}
