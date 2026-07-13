//
//  SettingsViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings · ViewModel
//

import Observation

/// Drives the Settings screen: edits and persists ``AppSettings``.
///
/// The engine is now chosen **per task** — each ``LLMTask`` gets its own engine and
/// Claude model — plus the Adzuna country preference. Adzuna credentials are baked in
/// at build time (Milestone K), so this screen only shows whether the build is
/// configured.
@MainActor
@Observable
final class SettingsViewModel {
    /// The per-task engine configs, edited in place.
    var engines: [LLMTask: TaskEngineConfig]
    var adzunaCountry: String

    /// Whether this build has baked Adzuna credentials (read-only status display).
    let adzunaConfigured: Bool
    /// Whether a `lualatex` install was found — the awesome-cv LaTeX export route needs it
    /// (Milestone E). Surfaced read-only in the About pane. Probed in the composition root.
    let latexAvailable: Bool

    /// The tasks to show, in display order.
    let tasks = LLMTask.allCases
    /// The Claude models available to pick from.
    let claudeModels = ClaudeModel.all

    private let store: SettingsStore

    init(store: SettingsStore, adzunaConfigured: Bool = false, latexAvailable: Bool = false) {
        self.store = store
        self.adzunaConfigured = adzunaConfigured
        self.latexAvailable = latexAvailable
        let settings = store.load()
        self.engines = settings.engines
        self.adzunaCountry = settings.adzunaCountry
    }

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
    }
}
