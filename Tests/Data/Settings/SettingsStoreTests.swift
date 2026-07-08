//
//  SettingsStoreTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Settings — load/save round-trips and AppSettings helpers.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// An in-memory `KeyValueStore` for tests.
private final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    var allKeys: [String] { Array(storage.keys) }

    func data(forKey key: String) -> Data? { storage[key] }
    func setData(_ data: Data?, forKey key: String) {
        if let data { storage[key] = data } else { storage[key] = nil }
    }
}

@Suite("SettingsStore & AppSettings")
struct SettingsStoreTests {

    @Test func loadReturnsDefaultWhenEmpty() {
        let store = SettingsStore(store: InMemoryStore())
        #expect(store.load() == AppSettings.default)
    }

    @Test func saveThenLoadRoundTrips() {
        let store = SettingsStore(store: InMemoryStore())
        var settings = AppSettings.default
        settings.llmChoice = .claude
        settings.adzunaAppID = "id"
        settings.adzunaAppKey = "key"
        settings.adzunaCountry = "gb"

        store.save(settings)
        #expect(store.load() == settings)
    }

    @Test func loadReturnsDefaultOnCorruptData() {
        let backing = InMemoryStore()
        let store = SettingsStore(store: backing)
        store.save(.default)                 // writes under SettingsStore's private key
        let key = backing.allKeys.first!     // discover it without hardcoding
        backing.setData(Data("not json".utf8), forKey: key)

        #expect(store.load() == AppSettings.default)
    }

    @Test func defaultsAreSensible() {
        let defaults = AppSettings.default
        #expect(defaults.llmChoice == .auto)
        #expect(defaults.adzunaCountry == "us")
        #expect(defaults.hasAdzunaCredentials == false)
    }

    @Test func hasAdzunaCredentialsRequiresBoth() {
        #expect(AppSettings(adzunaAppID: "id", adzunaAppKey: "").hasAdzunaCredentials == false)
        #expect(AppSettings(adzunaAppID: "", adzunaAppKey: "key").hasAdzunaCredentials == false)
        #expect(AppSettings(adzunaAppID: "id", adzunaAppKey: "key").hasAdzunaCredentials == true)
    }

    @Test func adzunaCredentialsMapThrough() {
        let settings = AppSettings(adzunaAppID: "id", adzunaAppKey: "key", adzunaCountry: "gb")
        #expect(settings.adzunaCredentials == AdzunaJobSource.Credentials(appID: "id", appKey: "key", country: "gb"))
    }
}
