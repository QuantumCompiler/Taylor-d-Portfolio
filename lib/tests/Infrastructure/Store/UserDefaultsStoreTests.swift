//
//  UserDefaultsStoreTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Store — UserDefaults-backed store against an isolated suite.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("UserDefaultsStore", .serialized)
struct UserDefaultsStoreTests {

    private static let suiteName = "UserDefaultsStoreTests"

    /// A fresh, isolated defaults domain for each test.
    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: Self.suiteName)!
        defaults.removePersistentDomain(forName: Self.suiteName)
        return defaults
    }

    @Test func setThenGetReturnsStoredData() {
        let store = UserDefaultsStore(defaults: makeDefaults())
        store.setData(Data("value".utf8), forKey: "k")
        #expect(store.data(forKey: "k") == Data("value".utf8))
    }

    @Test func getMissingKeyReturnsNil() {
        let store = UserDefaultsStore(defaults: makeDefaults())
        #expect(store.data(forKey: "absent") == nil)
    }

    @Test func settingNilRemovesEntry() {
        let store = UserDefaultsStore(defaults: makeDefaults())
        store.setData(Data("value".utf8), forKey: "k")
        store.setData(nil, forKey: "k")
        #expect(store.data(forKey: "k") == nil)
    }
}
