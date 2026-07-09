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
/// injected dictionary, or a test stub. Secrets like the Adzuna keys are baked in
/// at build time (see `BundleAppConfig`) rather than entered by the user, so a
/// correctly-built binary always has them and a missing key fails fast.
protocol AppConfig: Sendable {
    /// The Adzuna application ID, or `nil` when the build didn't supply one.
    var adzunaAppID: String? { get }
    /// The Adzuna application key, or `nil` when the build didn't supply one.
    var adzunaAppKey: String? { get }
}

extension AppConfig {
    /// Whether both Adzuna credentials were baked into this build (search is possible).
    var hasAdzunaCredentials: Bool {
        adzunaAppID != nil && adzunaAppKey != nil
    }
}
