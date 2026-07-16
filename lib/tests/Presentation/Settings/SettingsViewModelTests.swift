//
//  SettingsViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Settings
//

import Testing
@testable import Taylor_d_Portfolio

/// A build-time config stub with configurable Adzuna keys.
private struct StubConfig: AppConfig {
    var adzunaAppID: String?
    var adzunaAppKey: String?
}

@MainActor
@Suite("SettingsViewModel")
struct SettingsViewModelTests {

    /// A view model wired to a credentials store over the given build-time fallback.
    private func makeVM(
        configID: String? = nil,
        configKey: String? = nil
    ) -> (SettingsViewModel, JobSourceCredentialsStore) {
        let credentials = JobSourceCredentialsStore(
            store: PresentationMemoryStore(),
            config: StubConfig(adzunaAppID: configID, adzunaAppKey: configKey)
        )
        let vm = SettingsViewModel(store: SettingsStore(store: PresentationMemoryStore()), credentials: credentials)
        return (vm, credentials)
    }

    @Test func loadsExistingSettings() {
        let store = SettingsStore(store: PresentationMemoryStore())
        var settings = AppSettings.default
        settings.engines[.profile] = TaskEngineConfig(choice: .claude, claudeModel: "claude-fable-5")
        settings.engines[.ranking] = TaskEngineConfig(choice: .onDevice)
        settings.adzunaCountry = "gb"
        store.save(settings)

        let vm = SettingsViewModel(store: store)
        #expect(vm.config(for: .profile).choice == .claude)
        #expect(vm.config(for: .profile).claudeModel == "claude-fable-5")
        #expect(vm.config(for: .ranking).choice == .onDevice)
        #expect(vm.adzunaCountry == "gb")
    }

    @Test func saveThenReloadPersists() {
        let backing = PresentationMemoryStore()
        let vm = SettingsViewModel(store: SettingsStore(store: backing))
        vm.setChoice(.onDevice, for: .profile)
        vm.setChoice(.claude, for: .application)
        vm.setModel("claude-haiku-4-5", for: .application)
        vm.adzunaCountry = "ca"
        vm.save()

        let reloaded = SettingsViewModel(store: SettingsStore(store: backing))
        #expect(reloaded.config(for: .profile).choice == .onDevice)
        #expect(reloaded.config(for: .application).choice == .claude)
        #expect(reloaded.config(for: .application).claudeModel == "claude-haiku-4-5")
        #expect(reloaded.adzunaCountry == "ca")
    }

    @Test func defaultsWhenNothingStored() {
        let vm = SettingsViewModel(store: SettingsStore(store: PresentationMemoryStore()))
        #expect(vm.adzunaCountry == "us")
        #expect(vm.config(for: .profile).choice == .claude)
        #expect(vm.config(for: .profile).claudeModel == "claude-opus-4-8")
        #expect(vm.claudeModels.count == ClaudeModel.all.count)
        #expect(vm.tasks.count == LLMTask.allCases.count)
    }

    @Test func exposesConfiguredStatus() {
        let store = SettingsStore(store: PresentationMemoryStore())
        #expect(SettingsViewModel(store: store, adzunaConfigured: true).adzunaConfigured)
        #expect(SettingsViewModel(store: store, adzunaConfigured: false).adzunaConfigured == false)
        // Defaults to not-configured when the flag isn't supplied.
        #expect(SettingsViewModel(store: store).adzunaConfigured == false)
    }

    // MARK: Provider credentials (field-keyed, registry-driven — Milestones D/F/G)

    @Test func adzunaConfiguredSeededFromCredentialsStore() {
        let (configured, _) = makeVM(configID: "id", configKey: "key")
        #expect(configured.adzunaConfigured)
        #expect(configured.isConfigured(.adzuna))

        let (unconfigured, _) = makeVM()
        #expect(!unconfigured.adzunaConfigured)
    }

    @Test func enteringCredentialsPersistsLocksAndReResolves() {
        let (vm, credentials) = makeVM()   // no build-time fallback
        #expect(!vm.adzunaConfigured)

        vm.setCredentialBuffer("my-id", for: .adzunaAppID)
        vm.setCredentialBuffer("my-key", for: .adzunaAppKey)
        vm.save()

        #expect(vm.adzunaConfigured)                                   // re-resolved after save
        #expect(vm.hasStoredCredentials(.adzuna))
        #expect(vm.isCredentialSaved(.adzunaAppID) && vm.isCredentialSaved(.adzunaAppKey))
        #expect(vm.credentialBuffer(for: .adzunaAppID).isEmpty)        // buffers cleared
        #expect(credentials.value(for: .adzunaAppID) == "my-id")       // actually persisted
        #expect(credentials.value(for: .adzunaAppKey) == "my-key")
    }

    @Test func savedFlagsSeededFromStoredValues() {
        let credentials = JobSourceCredentialsStore(store: PresentationMemoryStore(), config: StubConfig())
        credentials.setValue("id", for: .adzunaAppID)   // App ID stored, App Key not
        let vm = SettingsViewModel(store: SettingsStore(store: PresentationMemoryStore()), credentials: credentials)
        #expect(vm.isCredentialSaved(.adzunaAppID))
        #expect(!vm.isCredentialSaved(.adzunaAppKey))
    }

    @Test func savingOnlyOneFieldLocksOnlyThatField() {
        let (vm, _) = makeVM()
        vm.setCredentialBuffer("just-the-id", for: .adzunaAppID)
        vm.save()
        #expect(vm.isCredentialSaved(.adzunaAppID))     // entered field locks
        #expect(!vm.isCredentialSaved(.adzunaAppKey))   // untouched field stays editable
    }

    @Test func clearingUnlocksAndRevertsToFallback() {
        let (vm, _) = makeVM(configID: "baked-id", configKey: "baked-key")
        vm.setCredentialBuffer("id", for: .adzunaAppID)
        vm.setCredentialBuffer("key", for: .adzunaAppKey)
        vm.save()
        #expect(vm.hasStoredCredentials(.adzuna))

        vm.clearCredentials(.adzuna)
        #expect(!vm.isCredentialSaved(.adzunaAppID) && !vm.isCredentialSaved(.adzunaAppKey))
        #expect(!vm.hasStoredCredentials(.adzuna))
        #expect(vm.adzunaConfigured)   // still configured via the build-time fallback
    }

    @Test func clearingWithoutFallbackMakesUnconfigured() {
        let (vm, _) = makeVM()   // no build-time keys
        vm.setCredentialBuffer("id", for: .adzunaAppID)
        vm.setCredentialBuffer("key", for: .adzunaAppKey)
        vm.save()
        #expect(vm.adzunaConfigured)

        vm.clearCredentials(.adzuna)
        #expect(!vm.adzunaConfigured)
        #expect(!vm.hasStoredCredentials(.adzuna))
    }

    @Test func buildTimeFallbackDoesNotLockFields() {
        let (vm, _) = makeVM(configID: "baked-id", configKey: "baked-key")
        #expect(vm.adzunaConfigured)
        #expect(!vm.isCredentialSaved(.adzunaAppID) && !vm.isCredentialSaved(.adzunaAppKey))
    }

    @Test func savingBlankCredentialsLeavesStoredValuesUnchanged() {
        let (vm, credentials) = makeVM()
        vm.setCredentialBuffer("id", for: .adzunaAppID)
        vm.setCredentialBuffer("key", for: .adzunaAppKey)
        vm.save()

        vm.adzunaCountry = "gb"   // a later save of only non-credential settings
        vm.save()
        #expect(credentials.value(for: .adzunaAppID) == "id")
        #expect(credentials.value(for: .adzunaAppKey) == "key")
    }

    @Test func jsearchKeyRidesTheSameMachineryIndependently() {
        // v0.6.0 Milestone F/G — a second provider needs no VM-specific code.
        let (vm, credentials) = makeVM()
        vm.setCredentialBuffer("rapid-key", for: .jsearchAPIKey)
        vm.save()
        #expect(vm.isCredentialSaved(.jsearchAPIKey))
        #expect(vm.hasStoredCredentials(.jsearch))
        #expect(vm.isConfigured(.jsearch))
        #expect(credentials.value(for: .jsearchAPIKey) == "rapid-key")
        #expect(credentials.value(for: .adzunaAppID) == nil)   // providers independent

        vm.clearCredentials(.jsearch)
        #expect(!vm.isCredentialSaved(.jsearchAPIKey))
        #expect(credentials.value(for: .jsearchAPIKey) == nil)
    }

    @Test func credentialControlsAreNoOpsWithoutAStore() {
        let vm = SettingsViewModel(store: SettingsStore(store: PresentationMemoryStore()), adzunaConfigured: true)
        vm.setCredentialBuffer("x", for: .adzunaAppID)
        vm.save()                    // persists engine/country settings; credentials no-op
        vm.clearCredentials(.adzuna) // no-op
        #expect(!vm.hasStoredCredentials(.adzuna))
        #expect(vm.adzunaConfigured) // unchanged (still the passed flag)
    }
}
