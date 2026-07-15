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

    // MARK: Adzuna credentials (Milestone D-D)

    @Test func adzunaConfiguredSeededFromCredentialsStore() {
        // A credentials store with baked keys makes the VM configured with no flag passed.
        let (configured, _) = makeVM(configID: "id", configKey: "key")
        #expect(configured.adzunaConfigured)

        let (unconfigured, _) = makeVM()
        #expect(!unconfigured.adzunaConfigured)
    }

    @Test func enteringCredentialsPersistsAndReResolves() {
        let (vm, credentials) = makeVM()   // no build-time fallback
        #expect(!vm.adzunaConfigured)

        vm.adzunaAppID = "my-id"
        vm.adzunaAppKey = "my-key"
        vm.save()

        #expect(vm.adzunaConfigured)                          // re-resolved after save
        #expect(vm.hasStoredAdzunaCredentials)
        #expect(vm.appIDSaved && vm.appKeySaved)              // both fields now locked/masked
        #expect(vm.adzunaAppID.isEmpty && vm.adzunaAppKey.isEmpty)   // buffers cleared
        #expect(credentials.value(for: .adzunaAppID) == "my-id")     // actually persisted
        #expect(credentials.value(for: .adzunaAppKey) == "my-key")
    }

    @Test func savedFlagsSeededFromStoredValues() {
        let credentials = JobSourceCredentialsStore(
            store: PresentationMemoryStore(), config: StubConfig()
        )
        credentials.setValue("id", for: .adzunaAppID)   // App ID stored, App Key not
        let vm = SettingsViewModel(store: SettingsStore(store: PresentationMemoryStore()), credentials: credentials)
        #expect(vm.appIDSaved)
        #expect(!vm.appKeySaved)
    }

    @Test func savingOnlyOneFieldLocksOnlyThatField() {
        let (vm, _) = makeVM()
        vm.adzunaAppID = "just-the-id"
        vm.save()
        #expect(vm.appIDSaved)          // entered field locks
        #expect(!vm.appKeySaved)        // untouched field stays editable
    }

    @Test func clearingUnlocksBothFields() {
        let (vm, _) = makeVM(configID: "baked-id", configKey: "baked-key")
        vm.adzunaAppID = "id"
        vm.adzunaAppKey = "key"
        vm.save()
        #expect(vm.appIDSaved && vm.appKeySaved)

        vm.clearAdzunaCredentials()
        #expect(!vm.appIDSaved && !vm.appKeySaved)   // fields editable again
    }

    @Test func buildTimeFallbackDoesNotLockFields() {
        // Baked keys make search available, but there's no user entry to mask — fields stay editable.
        let (vm, _) = makeVM(configID: "baked-id", configKey: "baked-key")
        #expect(vm.adzunaConfigured)
        #expect(!vm.appIDSaved && !vm.appKeySaved)
    }

    @Test func savingBlankCredentialsLeavesStoredValuesUnchanged() {
        let (vm, credentials) = makeVM()
        vm.adzunaAppID = "id"
        vm.adzunaAppKey = "key"
        vm.save()

        // A later save of only non-credential settings must not wipe the saved keys.
        vm.adzunaCountry = "gb"
        vm.save()
        #expect(vm.adzunaConfigured)
        #expect(credentials.value(for: .adzunaAppID) == "id")
        #expect(credentials.value(for: .adzunaAppKey) == "key")
    }

    @Test func clearingRevertsToBuildTimeFallback() {
        let (vm, _) = makeVM(configID: "baked-id", configKey: "baked-key")
        vm.adzunaAppID = "mine-id"
        vm.adzunaAppKey = "mine-key"
        vm.save()
        #expect(vm.hasStoredAdzunaCredentials)

        vm.clearAdzunaCredentials()
        #expect(!vm.hasStoredAdzunaCredentials)
        #expect(vm.adzunaConfigured)                          // still configured via the fallback
    }

    @Test func clearingWithoutFallbackMakesUnconfigured() {
        let (vm, _) = makeVM()   // no build-time keys
        vm.adzunaAppID = "id"
        vm.adzunaAppKey = "key"
        vm.save()
        #expect(vm.adzunaConfigured)

        vm.clearAdzunaCredentials()
        #expect(!vm.adzunaConfigured)
        #expect(!vm.hasStoredAdzunaCredentials)
    }

    @Test func enteringJSearchKeyPersistsLocksAndClears() {
        // v0.6.0 Milestone F — the JSearch key rides the same save/lock/clear machinery.
        let (vm, credentials) = makeVM()
        vm.jsearchAPIKey = "rapid-key"
        vm.save()
        #expect(vm.jsearchKeySaved)                          // field locks
        #expect(vm.hasStoredJSearchCredentials)
        #expect(vm.jsearchAPIKey.isEmpty)                    // buffer cleared
        #expect(credentials.value(for: .jsearchAPIKey) == "rapid-key")

        vm.clearJSearchCredentials()
        #expect(!vm.jsearchKeySaved)                         // unlocks
        #expect(credentials.value(for: .jsearchAPIKey) == nil)
    }

    @Test func savingAdzunaDoesNotTouchJSearchAndViceVersa() {
        let (vm, credentials) = makeVM()
        vm.adzunaAppID = "id"
        vm.adzunaAppKey = "key"
        vm.save()
        #expect(credentials.value(for: .jsearchAPIKey) == nil)   // JSearch untouched

        vm.jsearchAPIKey = "rk"
        vm.save()
        #expect(credentials.value(for: .adzunaAppID) == "id")    // Adzuna preserved
        #expect(credentials.value(for: .jsearchAPIKey) == "rk")
    }

    @Test func credentialControlsAreNoOpsWithoutAStore() {
        // Previews/tests without a credentials store: no crash, stays on the passed flag.
        let vm = SettingsViewModel(store: SettingsStore(store: PresentationMemoryStore()), adzunaConfigured: true)
        vm.adzunaAppID = "x"
        vm.save()                       // persists engine/country settings; credentials no-op
        vm.clearAdzunaCredentials()     // no-op
        #expect(!vm.hasStoredAdzunaCredentials)
        #expect(vm.adzunaConfigured)    // unchanged (still the passed flag)
    }
}
