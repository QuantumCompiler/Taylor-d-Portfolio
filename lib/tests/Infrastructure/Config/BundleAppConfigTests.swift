//
//  BundleAppConfigTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Config — build-time credential lookup.
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("BundleAppConfig")
struct BundleAppConfigTests {

    private func config(id: String?, key: String?) -> BundleAppConfig {
        var values: [String: String] = [:]
        if let id { values[BundleAppConfig.Key.adzunaAppID] = id }
        if let key { values[BundleAppConfig.Key.adzunaAppKey] = key }
        return BundleAppConfig(values: values)
    }

    @Test func bothPresent() {
        let c = config(id: "abc123", key: "def456")
        #expect(c.adzunaAppID == "abc123")
        #expect(c.adzunaAppKey == "def456")
        #expect(c.hasAdzunaCredentials)
    }

    @Test func bothMissing() {
        let c = config(id: nil, key: nil)
        #expect(c.adzunaAppID == nil)
        #expect(c.adzunaAppKey == nil)
        #expect(c.hasAdzunaCredentials == false)
    }

    @Test func partialIsNotConfigured() {
        #expect(config(id: "abc123", key: nil).hasAdzunaCredentials == false)
        #expect(config(id: nil, key: "def456").hasAdzunaCredentials == false)
    }

    @Test func emptyOrWhitespaceReadsAsAbsent() {
        // An unfilled `$(ADZUNA_APP_ID)` expands to "" — must read as not configured.
        let empty = config(id: "", key: "   ")
        #expect(empty.adzunaAppID == nil)
        #expect(empty.adzunaAppKey == nil)
        #expect(empty.hasAdzunaCredentials == false)
    }

    @Test func trimsSurroundingWhitespace() {
        let c = config(id: "  abc123  ", key: "\tdef456\n")
        #expect(c.adzunaAppID == "abc123")
        #expect(c.adzunaAppKey == "def456")
    }
}
