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
/// (Milestone D): entered here into the ``JobSourceCredentialsStore`` (stored locally on the
/// Mac), falling back to any build-time keys, so `adzunaConfigured` reflects resolution from
/// either source and is re-checked after a save.
@MainActor
@Observable
final class SettingsViewModel {
    /// The per-task engine configs, edited in place.
    var engines: [LLMTask: TaskEngineConfig]
    var adzunaCountry: String

    /// Whether Adzuna credentials resolve (user-entered or build-time) — the Adzuna status.
    /// Re-resolved after a save so the Settings status updates without relaunch.
    private(set) var adzunaConfigured: Bool
    /// The ids of every registered provider whose credentials currently resolve — pushed to the
    /// Search view so its availability gate + provider selector reflect what's configured
    /// (Milestone H). Re-resolved after every save/clear.
    private(set) var configuredProviderIDs: Set<String> = []
    /// Whether a `lualatex` install was found — the awesome-cv LaTeX export route needs it
    /// (Milestone E). Surfaced read-only in the About pane. Probed in the composition root.
    let latexAvailable: Bool
    /// Whether the LLM job source's engine is available (Milestone J) — its "Configured" status
    /// and its inclusion in `configuredProviderIDs` are **engine-based**, not credential-based.
    let llmSourceAvailable: Bool

    /// The tasks to show, in display order.
    let tasks = LLMTask.allCases
    /// The Claude models available to pick from.
    let claudeModels = ClaudeModel.all

    /// Per-field edit buffers, keyed by ``JobCredentialField`` (registry-driven, so a new
    /// provider needs no VM change). Never pre-filled with the stored secret; **empty means
    /// "leave the saved value unchanged"** on save. Cleared after a successful save.
    private var buffers: [JobCredentialField: String] = [:]
    /// The credential fields that currently have a **user-saved** value — drives the locked,
    /// masked display (a saved key is shown greyed and immutable, never revealed).
    private var savedFields: Set<JobCredentialField> = []

    private let store: SettingsStore
    private let credentials: JobSourceCredentialsStore?

    init(
        store: SettingsStore,
        credentials: JobSourceCredentialsStore? = nil,
        adzunaConfigured: Bool = false,
        latexAvailable: Bool = false,
        llmSourceAvailable: Bool = false
    ) {
        self.store = store
        self.credentials = credentials
        // When a credentials store is wired, it's the source of truth; the `adzunaConfigured`
        // argument is a fallback for previews/tests that don't supply one.
        self.adzunaConfigured = credentials?.hasCredentials(for: .adzuna) ?? adzunaConfigured
        self.latexAvailable = latexAvailable
        self.llmSourceAvailable = llmSourceAvailable
        let settings = store.load()
        self.engines = settings.engines
        self.adzunaCountry = settings.adzunaCountry
        self.savedFields = Self.storedFields(in: credentials)
        self.configuredProviderIDs = Self.resolvedProviderIDs(credentials, adzunaFallback: self.adzunaConfigured, llmAvailable: llmSourceAvailable)
    }

    /// The registered providers that are currently usable. Credentialed providers need their keys
    /// to resolve; the LLM provider (Milestone J) needs its **engine** available (not a key).
    /// Without a store (previews/tests), falls back to the `adzunaConfigured` flag for Adzuna only.
    private static func resolvedProviderIDs(_ credentials: JobSourceCredentialsStore?, adzunaFallback: Bool, llmAvailable: Bool) -> Set<String> {
        if let credentials {
            return Set(JobProviderRegistry.all.filter { descriptor in
                switch descriptor.kind {
                case .credentialed: return credentials.hasCredentials(for: descriptor.provider)
                case .llm:          return llmAvailable
                }
            }.map(\.id))
        }
        return adzunaFallback ? [JobProvider.adzuna.rawValue] : []
    }

    /// The credential fields that already have a user-saved value, across every registered
    /// provider — the source of the initial/refreshed locked state.
    private static func storedFields(in credentials: JobSourceCredentialsStore?) -> Set<JobCredentialField> {
        guard let credentials else { return [] }
        let fields = JobProviderRegistry.all.flatMap { $0.credentialFields.map(\.field) }
        return Set(fields.filter { credentials.hasStoredValue(for: $0) })
    }

    // MARK: Provider credentials (field-keyed, registry-driven — Milestones D/F/G)

    /// The edit-buffer value for `field` (empty when untouched this session).
    func credentialBuffer(for field: JobCredentialField) -> String { buffers[field] ?? "" }
    /// Sets the edit buffer for `field`.
    func setCredentialBuffer(_ value: String, for field: JobCredentialField) { buffers[field] = value }
    /// Whether `field` has a user-saved value (so it's shown locked + masked, not editable).
    func isCredentialSaved(_ field: JobCredentialField) -> Bool { savedFields.contains(field) }

    /// Whether `provider` is usable — its "Configured" status. Credentialed providers resolve
    /// their keys; the LLM provider (Milestone J) reports its **engine** availability instead.
    func isConfigured(_ provider: JobProvider) -> Bool {
        if provider == .llm { return llmSourceAvailable }
        if let credentials { return credentials.hasCredentials(for: provider) }
        return provider == .adzuna && adzunaConfigured   // previews/tests without a store
    }
    /// Whether the user has entered any of `provider`'s fields — gates its "Clear" affordance.
    func hasStoredCredentials(_ provider: JobProvider) -> Bool {
        (JobProviderRegistry.descriptor(for: provider)?.credentialFields ?? [])
            .contains { savedFields.contains($0.field) }
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

    /// Clears `provider`'s stored fields (reverting to any build-time keys), unlocking them for
    /// re-entry, and re-resolves state.
    func clearCredentials(_ provider: JobProvider) {
        guard let credentials else { return }
        for credentialField in JobProviderRegistry.descriptor(for: provider)?.credentialFields ?? [] {
            credentials.setValue(nil, for: credentialField.field)
            buffers[credentialField.field] = ""
        }
        refreshCredentialState()
    }

    func save() {
        store.save(settings)
        persistCredentials()
    }

    /// Persists any non-blank credential buffers (every provider's fields) to the store, clears
    /// the buffers, and re-resolves state. A blank buffer leaves the saved value untouched (so
    /// saving engine/country settings never wipes existing keys). The agent never sets these —
    /// the user types their own keys.
    private func persistCredentials() {
        guard let credentials else { return }
        for field in JobProviderRegistry.all.flatMap({ $0.credentialFields.map(\.field) }) {
            let value = buffers[field] ?? ""
            if !value.isBlank { credentials.setValue(value, for: field) }
        }
        buffers.removeAll()
        refreshCredentialState()
    }

    /// Re-reads the stored/resolved credential state after a save or clear, so the locked field
    /// displays and the availability banner reflect the change.
    private func refreshCredentialState() {
        savedFields = Self.storedFields(in: credentials)
        adzunaConfigured = credentials?.hasCredentials(for: .adzuna) ?? adzunaConfigured
        configuredProviderIDs = Self.resolvedProviderIDs(credentials, adzunaFallback: adzunaConfigured, llmAvailable: llmSourceAvailable)
    }
}

private extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
