//
//  JobSourceCredentialsStore.swift
//  Taylor'd Portfolio
//
//  Data · Settings — user-entered job-source API credentials, resolved over a build-time
//  fallback (Milestone D-B).
//

import Foundation

/// A job-search provider whose API needs credentials. Provider-keyed so Adzuna and any
/// future source (JSearch, The Muse — Milestone F) share one credential mechanism instead
/// of each being special-cased.
nonisolated enum JobProvider: String, Codable, Sendable, CaseIterable {
    case adzuna
    case jsearch

    /// The credential fields this provider requires before it can search.
    var requiredCredentials: [JobCredentialField] {
        switch self {
        case .adzuna:  return [.adzunaAppID, .adzunaAppKey]
        case .jsearch: return [.jsearchAPIKey]
        }
    }
}

/// Identifies one credential field of one provider (e.g. Adzuna's app id vs. app key).
/// The `storageKey` namespaces it in the backing `KeyValueStore`.
nonisolated struct JobCredentialField: Equatable, Hashable, Sendable {
    let provider: JobProvider
    let name: String

    /// The key under which this field is stored, e.g. `"adzuna.appID"`.
    var storageKey: String { "\(provider.rawValue).\(name)" }

    static let adzunaAppID = JobCredentialField(provider: .adzuna, name: "appID")
    static let adzunaAppKey = JobCredentialField(provider: .adzuna, name: "appKey")
    static let jsearchAPIKey = JobCredentialField(provider: .jsearch, name: "apiKey")
}

/// Resolves job-source API credentials from **user-entered values first, then the
/// build-time ``AppConfig`` fallback, then absent** (Milestone D).
///
/// User-entered values are written to the injected `KeyValueStore`. The composition root
/// backs it with `UserDefaults` for the personal dev build (the ``KeychainStore`` alternative
/// re-prompts on every ad-hoc-signed rebuild — see `Composition`), but the store is agnostic:
/// swap in `KeychainStore` behind the same port for a stably-signed / distributed build.
/// `AppConfig` stays an **optional** fallback so dev/CI builds that still bake in the Adzuna
/// keys keep working with no user action ("pure fallback, no seeding").
///
/// An empty/whitespace user entry is treated as **absent** (falls back), and `setValue`
/// clears the stored entry for an empty value — so leaving a field blank uses the baked-in
/// key, and clearing a field reverts to it.
nonisolated struct JobSourceCredentialsStore: Sendable {
    /// Secret storage for user-entered values (keychain-backed in production).
    let store: any KeyValueStore
    /// Build-time fallback (baked Adzuna keys), consulted only when no user value is set.
    let config: any AppConfig

    init(store: any KeyValueStore, config: any AppConfig) {
        self.store = store
        self.config = config
    }

    /// The resolved value for `field`: the user-entered value if present and non-empty,
    /// else the build-time fallback if non-empty, else `nil`.
    func value(for field: JobCredentialField) -> String? {
        if let entered = storedValue(for: field), !entered.isBlank {
            return entered
        }
        if let fallback = configFallback(for: field), !fallback.isBlank {
            return fallback
        }
        return nil
    }

    /// Stores a user-entered value for `field`. A `nil`, empty, or whitespace-only value
    /// **clears** the stored entry, reverting resolution to the build-time fallback.
    func setValue(_ value: String?, for field: JobCredentialField) {
        if let value, !value.isBlank {
            store.setData(Data(value.utf8), forKey: field.storageKey)
        } else {
            store.setData(nil, forKey: field.storageKey)
        }
    }

    /// Whether every credential `provider` requires resolves to a value — the generalised
    /// "search is possible" check (replacing `AppConfig.hasAdzunaCredentials`, which only
    /// saw the build-time source).
    func hasCredentials(for provider: JobProvider) -> Bool {
        provider.requiredCredentials.allSatisfy { value(for: $0) != nil }
    }

    /// Whether the **user** has entered a non-blank value for `field` — distinct from
    /// ``value(for:)``, which also honours the build-time fallback. Lets the UI offer a
    /// "clear my credentials" affordance only when there's a user entry to clear.
    func hasStoredValue(for field: JobCredentialField) -> Bool {
        guard let stored = storedValue(for: field) else { return false }
        return !stored.isBlank
    }

    /// Whether the user has entered any of `provider`'s credential fields.
    func hasStoredCredentials(for provider: JobProvider) -> Bool {
        provider.requiredCredentials.contains { hasStoredValue(for: $0) }
    }

    // MARK: Helpers

    private func storedValue(for field: JobCredentialField) -> String? {
        store.data(forKey: field.storageKey).map { String(decoding: $0, as: UTF8.self) }
    }

    /// The build-time fallback for the fields `AppConfig` can supply (only Adzuna's keys).
    private func configFallback(for field: JobCredentialField) -> String? {
        if field == .adzunaAppID { return config.adzunaAppID }
        if field == .adzunaAppKey { return config.adzunaAppKey }
        return nil
    }
}

private extension String {
    nonisolated var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
