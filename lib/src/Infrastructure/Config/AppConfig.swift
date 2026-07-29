//
//  AppConfig.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Config — build-time configuration port.
//

import Foundation

/// Read-only access to values baked into the app at build time (as opposed to
/// user-editable settings, which live behind `KeyValueStore`).
///
/// Declared in Infrastructure so the Data layer can assemble Adzuna credentials
/// without knowing whether the values come from the app bundle's Info.plist, an
/// injected dictionary, or a test stub. As of Milestone D the Adzuna keys are primarily
/// **user-entered** (via `JobSourceCredentialsStore`); the build-time values here remain an
/// optional **fallback**, so dev/CI builds that bake in `Secrets.xcconfig` keep working
/// without the user re-entering them.
protocol AppConfig: Sendable {
    /// The Adzuna application ID, or `nil` when the build didn't supply one.
    nonisolated var adzunaAppID: String? { get }
    /// The Adzuna application key, or `nil` when the build didn't supply one.
    nonisolated var adzunaAppKey: String? { get }
}

extension AppConfig {
    /// Whether both Adzuna credentials were baked into this build (search is possible).
    nonisolated var hasAdzunaCredentials: Bool {
        adzunaAppID != nil && adzunaAppKey != nil
    }
}
