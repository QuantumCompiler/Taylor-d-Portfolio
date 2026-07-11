//
//  RoleTitleStoreTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Search — persistence of the user's common role titles.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

private final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    func data(forKey key: String) -> Data? { storage[key] }
    func setData(_ data: Data?, forKey key: String) {
        if let data { storage[key] = data } else { storage[key] = nil }
    }
}

@Suite("RoleTitleStore")
struct RoleTitleStoreTests {

    @Test func loadReturnsEmptyWhenNothingStored() {
        #expect(RoleTitleStore(store: InMemoryStore()).load().isEmpty)
    }

    @Test func saveThenLoadRoundTrips() {
        let store = RoleTitleStore(store: InMemoryStore())
        store.save(["iOS Engineer", "Backend Engineer"])
        #expect(store.load() == ["iOS Engineer", "Backend Engineer"])
    }

    @Test func persistsAcrossStoreInstancesOnSharedBacking() {
        let backing = InMemoryStore()
        RoleTitleStore(store: backing).save(["Platform Engineer"])
        // A fresh store over the same backing reads what the first one wrote.
        #expect(RoleTitleStore(store: backing).load() == ["Platform Engineer"])
    }

    @Test func loadReturnsEmptyOnCorruptData() {
        let backing = InMemoryStore()
        let store = RoleTitleStore(store: backing)
        store.save(["x"])
        let key = "com.vivint.taylordportfolio.commonRoleTitles"
        backing.setData(Data("not json".utf8), forKey: key)
        #expect(store.load().isEmpty)
    }
}
