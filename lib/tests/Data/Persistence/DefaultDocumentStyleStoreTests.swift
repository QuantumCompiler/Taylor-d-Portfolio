//
//  DefaultDocumentStyleStoreTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — the default document-style pointer (v0.7.0 Milestone D).
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

@Suite("DefaultDocumentStyleStore")
struct DefaultDocumentStyleStoreTests {

    private func style(_ id: String, _ name: String) -> SavedDocumentStyle {
        SavedDocumentStyle(id: id, name: name, style: .default, createdAt: Date(timeIntervalSince1970: 0))
    }

    @Test func loadReturnsNilWhenNothingStored() {
        #expect(DefaultDocumentStyleStore(store: InMemoryStore()).load() == nil)
    }

    @Test func saveThenLoadRoundTrips() {
        let store = DefaultDocumentStyleStore(store: InMemoryStore())
        store.save("style-a")
        #expect(store.load() == "style-a")
    }

    @Test func savingNilClearsTheDefault() {
        let store = DefaultDocumentStyleStore(store: InMemoryStore())
        store.save("style-a")
        store.save(nil)
        #expect(store.load() == nil)
    }

    /// "Exactly one default" is true by construction — setting another replaces it, there is no
    /// per-style flag to get out of sync.
    @Test func settingADifferentDefaultReplacesTheOldOne() {
        let store = DefaultDocumentStyleStore(store: InMemoryStore())
        store.save("style-a")
        store.save("style-b")
        #expect(store.load() == "style-b")
    }

    @Test func persistsAcrossStoreInstancesOnSharedBacking() {
        let backing = InMemoryStore()
        DefaultDocumentStyleStore(store: backing).save("style-a")
        #expect(DefaultDocumentStyleStore(store: backing).load() == "style-a")
    }

    @Test func loadReturnsNilOnCorruptData() {
        let backing = InMemoryStore()
        backing.setData(Data("not json".utf8),
                        forKey: "com.veritum.taylordportfolio.defaultDocumentStyleID")
        #expect(DefaultDocumentStyleStore(store: backing).load() == nil)
    }

    /// Pins the namespaced key exactly — a preference key is a compatibility surface.
    @Test func theKeyIsTheNamespacedDefaultDocumentStyleID() {
        let backing = InMemoryStore()
        DefaultDocumentStyleStore(store: backing).save("style-a")
        #expect(backing.data(forKey: "com.veritum.taylordportfolio.defaultDocumentStyleID") != nil)
    }

    /// The two single-id pointers share one `UserDefaults` suite in the app, so a key collision
    /// would silently cross-wire them.
    @Test func theStylePointerDoesNotDisturbTheProfilePointer() {
        let backing = InMemoryStore()
        DefaultProfileStore(store: backing).save("profile-1")
        DefaultDocumentStyleStore(store: backing).save("style-1")

        #expect(DefaultProfileStore(store: backing).load() == "profile-1")
        #expect(DefaultDocumentStyleStore(store: backing).load() == "style-1")
    }

    // MARK: Resolving against the library

    @Test func resolvedReturnsTheStyleThePointerNames() {
        let store = DefaultDocumentStyleStore(store: InMemoryStore())
        store.save("b")

        #expect(store.resolved(in: [style("a", "A"), style("b", "B")])?.name == "B")
    }

    @Test func resolvedReturnsNilWhenNoDefaultIsSet() {
        // Styles exist, but none was chosen — the export must fall back to the built-in default
        // rather than picking one for the user.
        #expect(DefaultDocumentStyleStore(store: InMemoryStore())
            .resolved(in: [style("a", "A")]) == nil)
    }

    /// A pointer to a deleted style resolves to `nil`, **not** to some other style — deliberately
    /// unlike the profile call site's `?? profiles.first`. Silently applying a style the user
    /// never chose would change the document they're about to send.
    @Test func resolvedReturnsNilWhenThePointerDangles() {
        let store = DefaultDocumentStyleStore(store: InMemoryStore())
        store.save("deleted-id")

        #expect(store.resolved(in: [style("a", "A"), style("b", "B")]) == nil)
    }
}
