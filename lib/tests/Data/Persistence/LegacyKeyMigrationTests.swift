//
//  LegacyKeyMigrationTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — the com.vivint → com.veritum key migration.
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

@Suite("LegacyKeyMigration")
struct LegacyKeyMigrationTests {
    private let oldKey = "com.vivint.taylordportfolio.appSettings"
    private let newKey = "com.veritum.taylordportfolio.appSettings"

    @Test func copiesOldValueToNewKeyAndClearsOld() {
        let store = InMemoryStore()
        store.setData(Data("settings".utf8), forKey: oldKey)

        LegacyKeyMigration.run(on: store)

        #expect(store.data(forKey: newKey) == Data("settings".utf8))   // migrated
        #expect(store.data(forKey: oldKey) == nil)                     // old com.vivint key gone
    }

    @Test func migratesEveryKnownStoreKey() {
        let store = InMemoryStore()
        let pairs = [
            ("com.vivint.taylordportfolio.commonRoleTitles", "com.veritum.taylordportfolio.commonRoleTitles"),
            ("com.vivint.taylordportfolio.savedLocations", "com.veritum.taylordportfolio.savedLocations"),
            ("com.vivint.taylordportfolio.savedSalaryPresets", "com.veritum.taylordportfolio.savedSalaryPresets"),
            ("com.vivint.taylordportfolio.defaultProfileID", "com.veritum.taylordportfolio.defaultProfileID"),
        ]
        for (old, _) in pairs { store.setData(Data(old.utf8), forKey: old) }

        LegacyKeyMigration.run(on: store)

        for (old, new) in pairs {
            #expect(store.data(forKey: new) == Data(old.utf8))
            #expect(store.data(forKey: old) == nil)
        }
    }

    @Test func neverOverwritesAnExistingNewValue() {
        let store = InMemoryStore()
        store.setData(Data("old".utf8), forKey: oldKey)
        store.setData(Data("new".utf8), forKey: newKey)   // already migrated / newer

        LegacyKeyMigration.run(on: store)

        #expect(store.data(forKey: newKey) == Data("new".utf8))   // kept, not clobbered
        #expect(store.data(forKey: oldKey) == nil)
    }

    @Test func isIdempotentAcrossRuns() {
        let store = InMemoryStore()
        store.setData(Data("v1".utf8), forKey: oldKey)
        LegacyKeyMigration.run(on: store)

        // A stray old-key write after migration must NOT be re-migrated on a second run
        // (the done flag makes it a no-op).
        store.setData(Data("stray".utf8), forKey: oldKey)
        LegacyKeyMigration.run(on: store)

        #expect(store.data(forKey: newKey) == Data("v1".utf8))
        #expect(store.data(forKey: oldKey) == Data("stray".utf8))   // untouched second time
    }

    @Test func migratedValueIsReadableByTheStore() {
        // End-to-end: a value written under the old key is readable via the store afterwards.
        let store = InMemoryStore()
        let titles = try! JSONEncoder().encode(["iOS Engineer"])
        store.setData(titles, forKey: "com.vivint.taylordportfolio.commonRoleTitles")

        LegacyKeyMigration.run(on: store)

        #expect(RoleTitleStore(store: store).load() == ["iOS Engineer"])
    }
}
