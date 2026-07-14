//
//  Composition.swift
//  Taylor'd Portfolio
//
//  Presentation · App — the composition root: builds the object graph.
//

import Foundation
import SwiftData

/// Assembles the whole dependency graph: Infrastructure clients → Data gateways →
/// Business use cases → ViewModels. The one place allowed to reference every layer.
@MainActor
struct Composition {
    let settingsStore: SettingsStore

    private let appConfig: any AppConfig
    private let httpClient: any HTTPClient
    private let onDeviceClient: FoundationModelsClient
    private let documentExtractor: any DocumentTextExtractor
    /// Persistence for saved jobs — nil if the SwiftData store couldn't be created.
    private let recordStore: (any PersistentRecordStore)?
    /// Resolves job-source API credentials — user-entered (keychain) → build-time
    /// `AppConfig` → absent (Milestone D). Read live so Settings edits take effect.
    private let credentialsStore: JobSourceCredentialsStore

    init(appConfig: any AppConfig = BundleAppConfig()) {
        self.appConfig = appConfig
        // One-time: carry preferences over from the old com.vivint.* keys to the corrected
        // com.veritum.* namespace before any store reads them (bundle-id rename).
        LegacyKeyMigration.run(on: UserDefaultsStore())
        settingsStore = SettingsStore(store: UserDefaultsStore())
        httpClient = URLSessionHTTPClient()
        onDeviceClient = FoundationModelsClient()
        documentExtractor = PlatformDocumentTextExtractor()
        recordStore = Composition.makeRecordStore()
        // Credentials store: user-entered keys resolve over the build-time `AppConfig` fallback
        // (Milestone D). Backed by `UserDefaults`, not the keychain: this app is **unsandboxed
        // and ad-hoc-signed in dev**, so the legacy keychain re-prompts for access on every
        // rebuild (the signature changes each build, so "Always Allow" never sticks). The keys
        // are low-value Adzuna free-tier credentials (previously baked into the bundle), so the
        // plist is an acceptable home for a personal build. `KeychainStore` stays available
        // behind the same `KeyValueStore` port for a future stably-signed / distributed build.
        credentialsStore = JobSourceCredentialsStore(store: UserDefaultsStore(), config: appConfig)

        #if DEBUG
        // Fail-fast signal for developers: search needs Adzuna credentials from *either*
        // source. Surfaced to the user as a banner (see SearchViewModel); this is the
        // developer-facing console counterpart.
        if !credentialsStore.hasCredentials(for: .adzuna) {
            print("⚠️ [Taylor'd Portfolio] No Adzuna credentials resolved — none baked into "
                + "this build (copy Secrets.example.xcconfig → Secrets.xcconfig with "
                + "ADZUNA_APP_ID / ADZUNA_APP_KEY) and none entered in Settings → Adzuna. "
                + "Search will be unavailable until credentials are provided.")
        }
        #endif
    }

    /// Whether Adzuna credentials are available to search — resolved from the user's entries
    /// or the build-time fallback (Milestone D).
    var isAdzunaConfigured: Bool { credentialsStore.hasCredentials(for: .adzuna) }

    /// Builds the SwiftData-backed record store, or `nil` if the container can't be
    /// created — persistence then degrades to off rather than crashing the app.
    private static func makeRecordStore() -> (any PersistentRecordStore)? {
        guard let container = try? ModelContainer(for: StoredRecord.self) else { return nil }
        return SwiftDataRecordStore(modelContainer: container)
    }

    private var savedJobsRepository: SavedJobsRepository? {
        recordStore.map(SavedJobsRepository.init(store:))
    }
    private var savedApplicationsRepository: SavedApplicationsRepository? {
        recordStore.map(SavedApplicationsRepository.init(store:))
    }
    private var savedStatusRepository: SavedStatusRepository? {
        recordStore.map(SavedStatusRepository.init(store:))
    }
    private var savedProfilesRepository: SavedProfilesRepository? {
        recordStore.map(SavedProfilesRepository.init(store:))
    }

    /// Status use cases (nil when persistence is unavailable) — read by the detail view.
    var markStatus: MarkStatusUseCase? { savedStatusRepository.map { MarkStatusUseCase(repository: $0) } }
    var loadStatus: LoadStatusUseCase? { savedStatusRepository.map(LoadStatusUseCase.init(repository:)) }
    /// The saved-application loader — lets the Tracker detail offer a "View" affordance when a
    /// generated kit already exists (v0.5.0 Milestone A).
    var loadApplication: LoadApplicationUseCase? { savedApplicationsRepository.map(LoadApplicationUseCase.init(repository:)) }
    private var loadTrackedJobs: LoadTrackedJobsUseCase? {
        guard let savedJobsRepository, let savedStatusRepository else { return nil }
        return LoadTrackedJobsUseCase(jobs: savedJobsRepository, statuses: savedStatusRepository)
    }
    /// The cross-screen history join (seen / generated / tracked) — Milestone S-C.
    private var loadJobHistory: LoadJobHistoryUseCase? {
        guard let savedJobsRepository, let savedStatusRepository, let savedApplicationsRepository else { return nil }
        return LoadJobHistoryUseCase(jobs: savedJobsRepository, statuses: savedStatusRepository, applications: savedApplicationsRepository)
    }
    /// Fully-forget a saved job (job + status + kit) — Milestone V-A.
    private var deleteSavedJob: DeleteSavedJobUseCase? {
        guard let savedJobsRepository, let savedStatusRepository, let savedApplicationsRepository else { return nil }
        return DeleteSavedJobUseCase(jobs: savedJobsRepository, statuses: savedStatusRepository, applications: savedApplicationsRepository)
    }
    /// Remove a job from the Tracker without forgetting it — clears only its status so it
    /// returns to Results (v0.5.0).
    private var untrackJob: UntrackJobUseCase? { savedStatusRepository.map(UntrackJobUseCase.init(statuses:)) }

    // MARK: Gateways (read settings live, so Settings edits take effect immediately)

    private var llmProvider: any LLMProvider {
        SettingsBackedLLMProvider(store: settingsStore, onDeviceClient: onDeviceClient)
    }

    private var jobSource: any JobSource {
        SettingsBackedJobSource(credentials: credentialsStore, store: settingsStore, http: httpClient)
    }

    private var jobPostingSource: any JobPostingSource {
        LinkJobPostingSource(http: httpClient, extractor: llmProvider)
    }

    // MARK: Use cases

    private var buildProfile: BuildProfileUseCase { .init(provider: llmProvider) }
    private var importPortfolio: ImportPortfolioUseCase { .init(extractor: documentExtractor) }
    private var tidyDocument: TidyDocumentUseCase { .init(provider: llmProvider) }
    private var refineSummary: RefineSummaryUseCase { .init(provider: llmProvider) }
    private var searchAndRank: SearchAndRankUseCase {
        .init(jobSource: jobSource, ranker: JobRanker(provider: llmProvider))
    }
    private var generateApplication: GenerateApplicationUseCase { .init(provider: llmProvider) }
    private var generateToTarget: GenerateToTargetUseCase { .init(provider: llmProvider) }
    private var exportApplication: ExportApplicationUseCase {
        // The LaTeX compiler is wired unconditionally; it self-reports availability (a TeX
        // install) so the export UI only offers the awesome-cv route when it can run (Milestone D).
        .init(exporter: RoutingDocumentExporter(), compiler: LaTeXProcessClient())
    }
    private var fetchPosting: FetchPostingUseCase {
        .init(postingSource: jobPostingSource, ranker: JobRanker(provider: llmProvider))
    }
    /// Enriches a saved posting with richer detail (v0.6.0 Milestone A-D), preferring the full
    /// posting page (via the same `jobPostingSource` used for the link flow) over the snippet.
    private var enrichPosting: EnrichPostingUseCase {
        .init(provider: llmProvider, postingSource: jobPostingSource)
    }
    private var saveResults: SaveResultsUseCase? {
        savedJobsRepository.map(SaveResultsUseCase.init(repository:))
    }
    private var loadSavedJobs: LoadSavedJobsUseCase? {
        savedJobsRepository.map(LoadSavedJobsUseCase.init(repository:))
    }
    private var savedSearchesRepository: SavedSearchesRepository? {
        recordStore.map(SavedSearchesRepository.init(store:))
    }
    private var saveSearch: SaveSearchUseCase? {
        savedSearchesRepository.map { SaveSearchUseCase(repository: $0) }
    }
    private var loadSavedSearches: LoadSavedSearchesUseCase? {
        savedSearchesRepository.map(LoadSavedSearchesUseCase.init(repository:))
    }
    private var deleteSavedSearch: DeleteSavedSearchUseCase? {
        savedSearchesRepository.map(DeleteSavedSearchUseCase.init(repository:))
    }
    private var generationPresetsRepository: GenerationPresetsRepository? {
        recordStore.map(GenerationPresetsRepository.init(store:))
    }
    private var saveGenerationPreset: SaveGenerationPresetUseCase? {
        generationPresetsRepository.map { SaveGenerationPresetUseCase(repository: $0) }
    }
    private var loadGenerationPresets: LoadGenerationPresetsUseCase? {
        generationPresetsRepository.map(LoadGenerationPresetsUseCase.init(repository:))
    }
    private var deleteGenerationPreset: DeleteGenerationPresetUseCase? {
        generationPresetsRepository.map(DeleteGenerationPresetUseCase.init(repository:))
    }
    private var saveProfile: SaveProfileUseCase? {
        savedProfilesRepository.map { SaveProfileUseCase(repository: $0) }
    }
    var loadProfiles: LoadProfilesUseCase? {
        savedProfilesRepository.map(LoadProfilesUseCase.init(repository:))
    }
    /// Re-rank (and optionally re-enrich) one saved result against a chosen profile (v0.6.0 C).
    /// Nil when persistence isn't available (no store → nowhere to persist the refreshed result).
    var regenerateResult: RegenerateResultUseCase? {
        saveResults.map { RegenerateResultUseCase(provider: llmProvider, saveResults: $0, enrichPosting: enrichPosting) }
    }
    private var deleteProfile: DeleteProfileUseCase? {
        savedProfilesRepository.map(DeleteProfileUseCase.init(repository:))
    }

    // MARK: ViewModel factories

    func makePortfolioViewModel() -> PortfolioViewModel {
        .init(
            buildProfile: buildProfile,
            importPortfolio: importPortfolio,
            tidyDocument: tidyDocument,
            refineSummary: refineSummary,
            saveProfile: saveProfile,
            loadProfiles: loadProfiles,
            deleteProfile: deleteProfile,
            defaultProfileStore: DefaultProfileStore(store: UserDefaultsStore())
        )
    }
    func makeSearchViewModel() -> SearchViewModel {
        .init(
            searchAndRank: searchAndRank,
            suggestions: SuggestionProvider(),
            roleTitleStore: RoleTitleStore(store: UserDefaultsStore()),
            locationStore: LocationStore(store: UserDefaultsStore()),
            salaryPresetStore: SalaryPresetStore(store: UserDefaultsStore()),
            fetchPosting: fetchPosting,
            saveResults: saveResults,
            loadProfiles: loadProfiles,
            loadSavedJobs: loadSavedJobs,
            saveSearch: saveSearch,
            loadSavedSearches: loadSavedSearches,
            deleteSavedSearch: deleteSavedSearch,
            adzunaConfigured: isAdzunaConfigured
        )
    }
    func makeResultsViewModel() -> ResultsViewModel {
        .init(
            loadSavedJobs: loadSavedJobs,
            loadTrackedJobs: loadTrackedJobs,
            loadJobHistory: loadJobHistory,
            markStatus: markStatus,
            saveResults: saveResults,
            deleteSavedJob: deleteSavedJob,
            enrichPosting: enrichPosting
        )
    }
    func makeTrackerViewModel() -> TrackerViewModel {
        .init(
            loadTrackedJobs: loadTrackedJobs, loadJobHistory: loadJobHistory,
            untrackJob: untrackJob, deleteSavedJob: deleteSavedJob
        )
    }
    func makeSettingsViewModel() -> SettingsViewModel {
        .init(store: settingsStore, credentials: credentialsStore,
              latexAvailable: LaTeXProcessClient().isAvailable)
    }
    func makeApplicationViewModel() -> ApplicationViewModel {
        .init(
            generateApplication: generateApplication,
            generateToTarget: generateToTarget,
            saveApplication: savedApplicationsRepository.map(SaveApplicationUseCase.init(repository:)),
            loadApplication: loadApplication,
            exportApplication: exportApplication,
            saveGenerationPreset: saveGenerationPreset,
            loadGenerationPresets: loadGenerationPresets,
            deleteGenerationPreset: deleteGenerationPreset,
            loadProfiles: loadProfiles
        )
    }
}

// MARK: - Settings-backed adapters

/// An `LLMProvider` that rebuilds an `LLMRouter` from the current settings on each
/// call, so a change to the engine choice in Settings applies without a relaunch.
private nonisolated struct SettingsBackedLLMProvider: LLMProvider {
    let store: SettingsStore
    let onDeviceClient: FoundationModelsClient

    private func router() -> LLMRouter {
        // Snapshot settings once per call so a Settings edit applies without relaunch,
        // yet a single operation sees a consistent per-task engine map.
        let settings = store.load()
        let onDeviceClient = onDeviceClient
        return LLMRouter(
            configFor: { settings.config(for: $0) },
            onDevice: FoundationModelsProvider(client: onDeviceClient),
            // Build the Claude client per task so each task's chosen model applies.
            makeClaude: { model in
                let args = model.isEmpty ? [] : ["--model", model]
                return ClaudeCodeProvider(generator: ClaudeProcessClient(extraArguments: args))
            },
            isOnDeviceAvailable: { onDeviceClient.isAvailable }
        )
    }

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        try await router().buildProfile(fromPortfolio: portfolio)
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        try await router().rank(jobs: jobs, against: profile)
    }
    func rank(job: JobListing, against profile: CandidateProfile, instruction: String) async throws -> JobMatch {
        try await router().rank(job: job, against: profile, instruction: instruction)
    }
    func extractPosting(fromPageText pageText: String) async throws -> ExtractedPosting {
        try await router().extractPosting(fromPageText: pageText)
    }
    func enrichPosting(fromPostingText postingText: String) async throws -> PostingDetails {
        try await router().enrichPosting(fromPostingText: postingText)
    }
    func cleanPostingText(fromPageText pageText: String) async throws -> String {
        try await router().cleanPostingText(fromPageText: pageText)
    }
    func tidyDocument(rawText: String) async throws -> String {
        try await router().tidyDocument(rawText: rawText)
    }
    func refineSummary(profile: CandidateProfile, portfolio: String, instruction: String) async throws -> String {
        try await router().refineSummary(profile: profile, portfolio: portfolio, instruction: instruction)
    }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        try await router().buildTargetBrief(for: job)
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        try await router().generateApplication(for: job, profile: profile, brief: brief)
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?) async throws -> ApplicationKit {
        try await router().generateApplication(for: job, profile: profile, brief: brief, grounding: grounding)
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?, settings: GenerationSettings) async throws -> ApplicationKit {
        try await router().generateApplication(for: job, profile: profile, brief: brief, grounding: grounding, settings: settings)
    }
    func scoreApplication(for job: JobListing, brief: TargetBrief, kit: ApplicationKit) async throws -> JobMatch {
        try await router().scoreApplication(for: job, brief: brief, kit: kit)
    }
}

/// A `JobSource` that assembles Adzuna credentials from the `JobSourceCredentialsStore`
/// (user-entered id/key, falling back to build-time `AppConfig`) plus the user's chosen
/// country from settings — all read live on each search (Milestone D).
private nonisolated struct SettingsBackedJobSource: JobSource {
    let credentials: JobSourceCredentialsStore
    let store: SettingsStore
    let http: any HTTPClient

    func search(_ query: JobQuery) async throws -> [JobListing] {
        let creds = AdzunaJobSource.Credentials(
            appID: credentials.value(for: .adzunaAppID) ?? "",
            appKey: credentials.value(for: .adzunaAppKey) ?? "",
            country: store.load().adzunaCountry
        )
        let source = AdzunaJobSource(credentials: creds, http: http)
        return try await source.search(query)
    }
}
