//
//  LocationAndSalaryStoreTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Search — persistence of saved locations + salary presets (U-B / U-C).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

private final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    func data(forKey key: String) -> Data? { storage[key] }
    func setData(_ data: Data?, forKey key: String) { storage[key] = data }
}

@Suite("LocationStore")
struct LocationStoreTests {
    @Test func roundTripsAndPersistsOnSharedBacking() {
        let backing = InMemoryStore()
        LocationStore(store: backing).save(["Lehi, UT", "Remote"])
        #expect(LocationStore(store: backing).load() == ["Lehi, UT", "Remote"])
    }

    @Test func emptyAndCorruptLoadToEmpty() {
        let backing = InMemoryStore()
        #expect(LocationStore(store: backing).load().isEmpty)
        backing.setData(Data("nope".utf8), forKey: "com.veritum.taylordportfolio.savedLocations")
        #expect(LocationStore(store: backing).load().isEmpty)
    }
}

@Suite("SalaryPresetStore")
struct SalaryPresetStoreTests {
    @Test func roundTripsAndPersistsOnSharedBacking() {
        let backing = InMemoryStore()
        SalaryPresetStore(store: backing).save([90_000, 300_000])
        #expect(SalaryPresetStore(store: backing).load() == [90_000, 300_000])
    }

    @Test func emptyAndCorruptLoadToEmpty() {
        let backing = InMemoryStore()
        #expect(SalaryPresetStore(store: backing).load().isEmpty)
        backing.setData(Data("nope".utf8), forKey: "com.veritum.taylordportfolio.savedSalaryPresets")
        #expect(SalaryPresetStore(store: backing).load().isEmpty)
    }
}

@Suite("SuggestionProvider merges")
struct SuggestionProviderMergeTests {
    @Test func locationsMergeStaticThenSavedDeduped() {
        let provider = SuggestionProvider(locations: ["Remote", "Lehi, UT"])
        let merged = provider.locationSuggestions(saved: ["Boston, MA", "remote"])  // "remote" dupes "Remote"
        #expect(merged == ["Remote", "Lehi, UT", "Boston, MA"])
    }

    @Test func salaryPresetsMergeSortedAndDeduped() {
        let merged = SuggestionProvider.salaryPresets(saved: [90_000, 50_000])  // 50k already a preset
        #expect(merged.contains(90_000))
        #expect(merged == merged.sorted())
        #expect(merged.filter { $0 == 50_000 }.count == 1)
    }
}
