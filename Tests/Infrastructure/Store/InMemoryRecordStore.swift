//
//  InMemoryRecordStore.swift
//  Taylor'd PortfolioTests
//
//  Tests · shared — a fast, SwiftData-free PersistentRecordStore for unit tests.
//

import Foundation
@testable import Taylor_d_Portfolio

/// An in-memory ``PersistentRecordStore`` for tests that don't need real SwiftData.
final class InMemoryRecordStore: PersistentRecordStore, @unchecked Sendable {
    private var storage: [String: (kind: String, data: Data)] = [:]
    private func key(_ kind: String, _ id: String) -> String { "\(kind)\u{1}\(id)" }

    func upsert(kind: String, id: String, data: Data) async throws {
        storage[key(kind, id)] = (kind, data)
    }
    func records(ofKind kind: String) async throws -> [Data] {
        storage.values.filter { $0.kind == kind }.map(\.data)
    }
    func record(ofKind kind: String, id: String) async throws -> Data? {
        storage[key(kind, id)]?.data
    }
    func delete(kind: String, id: String) async throws {
        storage[key(kind, id)] = nil
    }
}
