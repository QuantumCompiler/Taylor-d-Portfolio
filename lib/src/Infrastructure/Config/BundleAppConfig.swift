//
//  BundleAppConfig.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Config — AppConfig backed by the app bundle's Info.plist.
//

import Foundation

/// The production `AppConfig`, reading values baked into the app bundle's
/// Info.plist at build time.
///
/// The Info.plist keys (`AdzunaAppID` / `AdzunaAppKey`) are populated from a
/// gitignored `Secrets.xcconfig` via `$(ADZUNA_APP_ID)` / `$(ADZUNA_APP_KEY)`
/// references, so credentials never live in source control or in user settings.
///
/// The raw lookup is injectable (mirroring `UserDefaultsStore(defaults:)`) so tests
/// exercise present / missing / partial configurations without needing a real bundle.
nonisolated struct BundleAppConfig: AppConfig {
    let adzunaAppID: String?
    let adzunaAppKey: String?

    /// Info.plist key names populated from the xcconfig at build time.
    enum Key {
        static let adzunaAppID = "AdzunaAppID"
        static let adzunaAppKey = "AdzunaAppKey"
    }

    /// Builds from a raw key → value lookup (injectable for tests). Values that are
    /// empty or whitespace-only are treated as absent — an unfilled `$(ADZUNA_APP_ID)`
    /// expands to an empty string, which must read as "not configured".
    init(values: [String: String]) {
        adzunaAppID = Self.normalized(values[Key.adzunaAppID])
        adzunaAppKey = Self.normalized(values[Key.adzunaAppKey])
    }

    /// Reads the values baked into `bundle`'s Info.plist (the app bundle by default).
    init(bundle: Bundle = .main) {
        self.init(values: [
            Key.adzunaAppID: bundle.object(forInfoDictionaryKey: Key.adzunaAppID) as? String ?? "",
            Key.adzunaAppKey: bundle.object(forInfoDictionaryKey: Key.adzunaAppKey) as? String ?? "",
        ])
    }

    /// Trims whitespace and maps empty to `nil` so unfilled build variables read as absent.
    private static func normalized(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else { return nil }
        return trimmed
    }
}
