//
//  LegacyKeyMigration.swift
//  Taylor'd Portfolio
//
//  Data · Persistence — one-time UserDefaults key rename (com.vivint → com.veritum).
//

import Foundation

/// Migrates the app's `UserDefaults`-backed preferences from their old `com.vivint.*`
/// keys to the corrected `com.veritum.*` bundle namespace, once.
///
/// The bundle identifier was corrected from `com.vivint.…` to `com.veritum.…`; the
/// preference keys shared that prefix, so this copies any values still under the old keys
/// to the new ones and clears the old keys. Idempotent — guarded by a done flag and it
/// never clobbers a value already present under a new key. Safe to delete once no install
/// predating the rename remains.
nonisolated enum LegacyKeyMigration {
    /// The old → new key renames. Old keys are the pre-rename `com.vivint.*` names; keep
    /// these literal (the stores no longer reference them).
    private static let renames: [(old: String, new: String)] = [
        ("com.vivint.taylordportfolio.appSettings", "com.veritum.taylordportfolio.appSettings"),
        ("com.vivint.taylordportfolio.commonRoleTitles", "com.veritum.taylordportfolio.commonRoleTitles"),
        ("com.vivint.taylordportfolio.savedLocations", "com.veritum.taylordportfolio.savedLocations"),
        ("com.vivint.taylordportfolio.savedSalaryPresets", "com.veritum.taylordportfolio.savedSalaryPresets"),
        ("com.vivint.taylordportfolio.defaultProfileID", "com.veritum.taylordportfolio.defaultProfileID"),
    ]

    /// Set once the migration has run, so it's a no-op on every later launch.
    private static let doneFlagKey = "com.veritum.taylordportfolio.legacyKeyMigration.v1"

    /// Runs the migration against `store` if it hasn't run before. Copies each old key's
    /// value to its new key (without overwriting an existing new value), removes the old
    /// key, and records completion.
    static func run(on store: any KeyValueStore) {
        guard store.data(forKey: doneFlagKey) == nil else { return }
        for rename in renames {
            if store.data(forKey: rename.new) == nil, let legacy = store.data(forKey: rename.old) {
                store.setData(legacy, forKey: rename.new)
            }
            store.setData(nil, forKey: rename.old)   // drop the old com.vivint key
        }
        store.setData(Data([1]), forKey: doneFlagKey)
    }
}
