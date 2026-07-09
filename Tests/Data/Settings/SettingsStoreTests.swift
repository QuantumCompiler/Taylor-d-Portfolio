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
        settings.engines[.profile] = TaskEngineConfig(choice: .onDevice, claudeModel: "claude-sonnet-5")
        settings.engines[.application] = TaskEngineConfig(choice: .auto, claudeModel: "claude-fable-5")
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
        #expect(defaults.adzunaCountry == "us")
        // On-device is no longer automatic: every task defaults to Claude on the default model.
        for task in LLMTask.allCases {
            #expect(defaults.config(for: task).choice == .claude)
            #expect(defaults.config(for: task).claudeModel == "claude-opus-4-8")
        }
    }

    @Test func configForFallsBackToDefaultWhenTaskMissing() {
        var settings = AppSettings(engines: [:], adzunaCountry: "us")
        #expect(settings.config(for: .profile) == .default)   // unset → default

        settings.engines[.profile] = TaskEngineConfig(choice: .onDevice)
        #expect(settings.config(for: .profile).choice == .onDevice)
        #expect(settings.config(for: .ranking) == .default)   // others still default
    }

    @Test func claudeModelArgumentsBuildTheModelFlag() {
        #expect(TaskEngineConfig(claudeModel: "claude-sonnet-5").claudeModelArguments == ["--model", "claude-sonnet-5"])
        #expect(TaskEngineConfig(claudeModel: "").claudeModelArguments == [])   // empty = CLI default
    }

    @Test func claudeModelCatalogIsWellFormed() {
        #expect(ClaudeModel.all.contains { $0.id == "claude-fable-5" })
        #expect(ClaudeModel.all.contains { $0.id == ClaudeModel.defaultID })
        #expect(ClaudeModel.isKnown("claude-opus-4-8"))
        #expect(ClaudeModel.isKnown("gpt-4") == false)
        // Ids are unique.
        #expect(Set(ClaudeModel.all.map(\.id)).count == ClaudeModel.all.count)
    }
}
