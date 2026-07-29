//
//  JobSourceCredentialsStoreTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Settings — credential resolution order (user → build-time → absent).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// An in-memory `KeyValueStore` for tests (stands in for the keychain).
private final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    var allKeys: [String] { Array(storage.keys) }

    func data(forKey key: String) -> Data? { storage[key] }
    func setData(_ data: Data?, forKey key: String) {
        if let data { storage[key] = data } else { storage[key] = nil }
    }
}

/// A build-time config stub with configurable Adzuna keys.
private struct StubAppConfig: AppConfig {
    var adzunaAppID: String?
    var adzunaAppKey: String?
}

@Suite("JobSourceCredentialsStore")
struct JobSourceCredentialsStoreTests {

    private func makeStore(
        config: StubAppConfig = StubAppConfig(adzunaAppID: nil, adzunaAppKey: nil)
    ) -> (JobSourceCredentialsStore, InMemoryStore) {
        let backing = InMemoryStore()
        return (JobSourceCredentialsStore(store: backing, config: config), backing)
    }

    // MARK: Resolution order

    @Test func userValueWinsOverBuildTimeFallback() {
        let (store, _) = makeStore(config: StubAppConfig(adzunaAppID: "baked-id", adzunaAppKey: "baked-key"))
        store.setValue("my-id", for: .adzunaAppID)
        #expect(store.value(for: .adzunaAppID) == "my-id")           // user entry wins
        #expect(store.value(for: .adzunaAppKey) == "baked-key")      // untouched field falls back
    }

    @Test func fallsBackToBuildTimeWhenNoUserValue() {
        let (store, _) = makeStore(config: StubAppConfig(adzunaAppID: "baked-id", adzunaAppKey: "baked-key"))
        #expect(store.value(for: .adzunaAppID) == "baked-id")
        #expect(store.value(for: .adzunaAppKey) == "baked-key")
    }

    @Test func absentEverywhereReturnsNil() {
        let (store, _) = makeStore()   // no user value, no baked keys
        #expect(store.value(for: .adzunaAppID) == nil)
        #expect(store.value(for: .adzunaAppKey) == nil)
    }

    // MARK: Set / clear semantics

    @Test func clearingUserValueRevertsToFallback() {
        let (store, _) = makeStore(config: StubAppConfig(adzunaAppID: "baked-id", adzunaAppKey: nil))
        store.setValue("my-id", for: .adzunaAppID)
        store.setValue(nil, for: .adzunaAppID)
        #expect(store.value(for: .adzunaAppID) == "baked-id")        // back to the baked key
    }

    @Test func emptyOrWhitespaceUserValueIsTreatedAsAbsent() {
        let (store, backing) = makeStore(config: StubAppConfig(adzunaAppID: "baked-id", adzunaAppKey: nil))
        store.setValue("my-id", for: .adzunaAppID)
        store.setValue("   ", for: .adzunaAppID)                     // blank clears
        #expect(store.value(for: .adzunaAppID) == "baked-id")
        #expect(backing.allKeys.isEmpty)                            // nothing left persisted
    }

    @Test func setValueRoundTripsWithoutFallback() {
        let (store, _) = makeStore()   // no baked keys
        store.setValue("user-key", for: .adzunaAppKey)
        #expect(store.value(for: .adzunaAppKey) == "user-key")
    }

    @Test func emptyBuildTimeFallbackIsNotUsed() {
        let (store, _) = makeStore(config: StubAppConfig(adzunaAppID: "", adzunaAppKey: "  "))
        #expect(store.value(for: .adzunaAppID) == nil)
        #expect(store.value(for: .adzunaAppKey) == nil)
    }

    // MARK: hasCredentials

    @Test func hasCredentialsTrueWhenAllFieldsResolve() {
        let (userOnly, _) = makeStore()
        userOnly.setValue("id", for: .adzunaAppID)
        userOnly.setValue("key", for: .adzunaAppKey)
        #expect(userOnly.hasCredentials(for: .adzuna))

        let (baked, _) = makeStore(config: StubAppConfig(adzunaAppID: "id", adzunaAppKey: "key"))
        #expect(baked.hasCredentials(for: .adzuna))
    }

    @Test func hasCredentialsFalseWhenAnyFieldMissing() {
        let (store, _) = makeStore(config: StubAppConfig(adzunaAppID: "id", adzunaAppKey: nil))
        #expect(!store.hasCredentials(for: .adzuna))               // key missing
        store.setValue("key", for: .adzunaAppKey)
        #expect(store.hasCredentials(for: .adzuna))
    }

    @Test func hasCredentialsCanMixUserAndBuildTimeSources() {
        // App id baked in, app key entered by the user — both sources satisfy the check.
        let (store, _) = makeStore(config: StubAppConfig(adzunaAppID: "baked-id", adzunaAppKey: nil))
        store.setValue("user-key", for: .adzunaAppKey)
        #expect(store.hasCredentials(for: .adzuna))
    }

    // MARK: Field / provider metadata

    @Test func fieldsStoreUnderNamespacedKeys() {
        #expect(JobCredentialField.adzunaAppID.storageKey == "adzuna.appID")
        #expect(JobCredentialField.adzunaAppKey.storageKey == "adzuna.appKey")
    }

    @Test func setValuePersistsUnderTheFieldStorageKey() {
        let (store, backing) = makeStore()
        store.setValue("v", for: .adzunaAppID)
        #expect(backing.allKeys == ["adzuna.appID"])
    }

    @Test func adzunaRequiresBothKeys() {
        #expect(JobProvider.adzuna.requiredCredentials == [.adzunaAppID, .adzunaAppKey])
    }

    @Test func jsearchRequiresItsApiKey() {
        // v0.6.0 Milestone F — a second provider shares the same credential mechanism.
        #expect(JobProvider.jsearch.requiredCredentials == [.jsearchAPIKey])
        #expect(JobCredentialField.jsearchAPIKey.storageKey == "jsearch.apiKey")

        let (store, _) = makeStore()
        #expect(!store.hasCredentials(for: .jsearch))
        store.setValue("rapid-key", for: .jsearchAPIKey)
        #expect(store.hasCredentials(for: .jsearch))
        #expect(store.value(for: .jsearchAPIKey) == "rapid-key")
        #expect(!store.hasCredentials(for: .adzuna))   // providers are independent
    }

    // MARK: Stored-only checks (distinguish user entry from build-time fallback)

    @Test func hasStoredValueReflectsUserEntryNotFallback() {
        let (store, _) = makeStore(config: StubAppConfig(adzunaAppID: "baked-id", adzunaAppKey: "baked-key"))
        // Resolves via the fallback, but the user hasn't stored anything.
        #expect(store.value(for: .adzunaAppID) == "baked-id")
        #expect(!store.hasStoredValue(for: .adzunaAppID))

        store.setValue("mine", for: .adzunaAppID)
        #expect(store.hasStoredValue(for: .adzunaAppID))
    }

    @Test func hasStoredCredentialsTrueWhenAnyFieldEntered() {
        let (store, _) = makeStore(config: StubAppConfig(adzunaAppID: "baked-id", adzunaAppKey: "baked-key"))
        #expect(!store.hasStoredCredentials(for: .adzuna))     // only build-time so far
        store.setValue("mine", for: .adzunaAppKey)
        #expect(store.hasStoredCredentials(for: .adzuna))      // one user field is enough
    }
}
