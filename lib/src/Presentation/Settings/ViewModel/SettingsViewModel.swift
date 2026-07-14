//
//  SettingsViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings · ViewModel
//

import Foundation
import Observation

/// Drives the Settings screen: edits and persists ``AppSettings`` and the user's job-source
/// API credentials.
///
/// The engine is chosen **per task** — each ``LLMTask`` gets its own engine and Claude
/// model — plus the Adzuna country preference. Adzuna credentials are **user-editable**
/// (Milestone D): entered here into the keychain-backed ``JobSourceCredentialsStore``,
/// falling back to any build-time keys, so `adzunaConfigured` reflects resolution from
/// either source and is re-checked after a save.
@MainActor
@Observable
final class SettingsViewModel {
    /// The per-task engine configs, edited in place.
    var engines: [LLMTask: TaskEngineConfig]
    var adzunaCountry: String

    /// Edit buffers for the Adzuna credential fields. Never pre-filled with the stored
    /// secret; **empty means "leave the saved value unchanged"** on save (so saving other
    /// settings doesn't wipe existing keys). Cleared after a successful save.
    var adzunaAppID: String = ""
    var adzunaAppKey: String = ""

    /// Whether Adzuna credentials resolve (user-entered or build-time) — the search-
    /// availability status. Re-resolved after a save so the banner updates without relaunch.
    private(set) var adzunaConfigured: Bool

    /// Whether each Adzuna field has a **user-saved** value. Drives the locked, masked field
    /// display (a saved key is shown greyed-out and immutable, never revealed). Observable so
    /// the field re-locks the moment it's saved / unlocks when cleared.
    private(set) var appIDSaved: Bool
    private(set) var appKeySaved: Bool
    /// Whether a `lualatex` install was found — the awesome-cv LaTeX export route needs it
    /// (Milestone E). Surfaced read-only in the About pane. Probed in the composition root.
    let latexAvailable: Bool

    /// The tasks to show, in display order.
    let tasks = LLMTask.allCases
    /// The Claude models available to pick from.
    let claudeModels = ClaudeModel.all

    private let store: SettingsStore
    private let credentials: JobSourceCredentialsStore?

    init(
        store: SettingsStore,
        credentials: JobSourceCredentialsStore? = nil,
        adzunaConfigured: Bool = false,
        latexAvailable: Bool = false
    ) {
        self.store = store
        self.credentials = credentials
        // When a credentials store is wired, it's the source of truth; the `adzunaConfigured`
        // argument is a fallback for previews/tests that don't supply one.
        self.adzunaConfigured = credentials?.hasCredentials(for: .adzuna) ?? adzunaConfigured
        self.appIDSaved = credentials?.hasStoredValue(for: .adzunaAppID) ?? false
        self.appKeySaved = credentials?.hasStoredValue(for: .adzunaAppKey) ?? false
        self.latexAvailable = latexAvailable
        let settings = store.load()
        self.engines = settings.engines
        self.adzunaCountry = settings.adzunaCountry
    }

    /// Whether the user has entered Adzuna credentials (vs. relying on build-time keys) —
    /// gates the "Clear saved credentials" affordance.
    var hasStoredAdzunaCredentials: Bool { appIDSaved || appKeySaved }

    /// The config for `task`, defaulting when unset.
    func config(for task: LLMTask) -> TaskEngineConfig {
        engines[task] ?? .default
    }

    /// Sets the engine choice for `task`.
    func setChoice(_ choice: LLMChoice, for task: LLMTask) {
        var config = config(for: task)
        config.choice = choice
        engines[task] = config
    }

    /// Sets the Claude model for `task`.
    func setModel(_ model: String, for task: LLMTask) {
        var config = config(for: task)
        config.claudeModel = model
        engines[task] = config
    }

    /// The current field values as an ``AppSettings`` value.
    var settings: AppSettings {
        AppSettings(engines: engines, adzunaCountry: adzunaCountry)
    }

    func save() {
        store.save(settings)
        persistAdzunaCredentials()
    }

    /// Persists any non-blank credential buffers to the store, clears the buffers, and
    /// re-resolves availability. A blank buffer leaves the saved value untouched (so saving
    /// engine/country settings never wipes existing keys). The agent never sets these — the
    /// user types their own keys.
    private func persistAdzunaCredentials() {
        guard let credentials else { return }
        if !adzunaAppID.isBlank { credentials.setValue(adzunaAppID, for: .adzunaAppID) }
        if !adzunaAppKey.isBlank { credentials.setValue(adzunaAppKey, for: .adzunaAppKey) }
        adzunaAppID = ""
        adzunaAppKey = ""
        refreshAdzunaState()
    }

    /// Clears the user's stored Adzuna credentials (reverting to any build-time keys),
    /// unlocking the fields for re-entry, and re-resolves availability.
    func clearAdzunaCredentials() {
        guard let credentials else { return }
        credentials.setValue(nil, for: .adzunaAppID)
        credentials.setValue(nil, for: .adzunaAppKey)
        adzunaAppID = ""
        adzunaAppKey = ""
        refreshAdzunaState()
    }

    /// Re-reads the stored/resolved credential state after a save or clear, so the locked
    /// field display and the availability banner both reflect the change.
    private func refreshAdzunaState() {
        guard let credentials else { return }
        appIDSaved = credentials.hasStoredValue(for: .adzunaAppID)
        appKeySaved = credentials.hasStoredValue(for: .adzunaAppKey)
        adzunaConfigured = credentials.hasCredentials(for: .adzuna)
    }
}

private extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
