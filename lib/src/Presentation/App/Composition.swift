//
//  Composition.swift
//  Taylor'd Portfolio
//
//  Presentation · App — the composition root: builds the object graph.
//

import Foundation

/// Assembles the whole dependency graph: Infrastructure clients → Data gateways →
/// Business use cases → ViewModels. The one place allowed to reference every layer.
@MainActor
struct Composition {
    let settingsStore: SettingsStore

    private let httpClient: any HTTPClient
    private let onDeviceClient: FoundationModelsClient
    private let claudeClient: ClaudeProcessClient
    private let documentExtractor: any DocumentTextExtractor

    init() {
        settingsStore = SettingsStore(store: UserDefaultsStore())
        httpClient = URLSessionHTTPClient()
        onDeviceClient = FoundationModelsClient()
        claudeClient = ClaudeProcessClient()
        documentExtractor = PlatformDocumentTextExtractor()
    }

    // MARK: Gateways (read settings live, so Settings edits take effect immediately)

    private var llmProvider: any LLMProvider {
        SettingsBackedLLMProvider(store: settingsStore, onDeviceClient: onDeviceClient, claudeClient: claudeClient)
    }

    private var jobSource: any JobSource {
        SettingsBackedJobSource(store: settingsStore, http: httpClient)
    }

    // MARK: Use cases

    private var buildProfile: BuildProfileUseCase { .init(provider: llmProvider) }
    private var importPortfolio: ImportPortfolioUseCase { .init(extractor: documentExtractor) }
    private var searchAndRank: SearchAndRankUseCase {
        .init(jobSource: jobSource, ranker: JobRanker(provider: llmProvider))
    }
    private var generateApplication: GenerateApplicationUseCase { .init(provider: llmProvider) }

    // MARK: ViewModel factories

    func makePortfolioViewModel() -> PortfolioViewModel {
        .init(buildProfile: buildProfile, importPortfolio: importPortfolio)
    }
    func makeSearchViewModel() -> SearchViewModel { .init(searchAndRank: searchAndRank) }
    func makeSettingsViewModel() -> SettingsViewModel { .init(store: settingsStore) }
    func makeApplicationViewModel() -> ApplicationViewModel { .init(generateApplication: generateApplication) }
}

// MARK: - Settings-backed adapters

/// An `LLMProvider` that rebuilds an `LLMRouter` from the current settings on each
/// call, so a change to the engine choice in Settings applies without a relaunch.
private nonisolated struct SettingsBackedLLMProvider: LLMProvider {
    let store: SettingsStore
    let onDeviceClient: FoundationModelsClient
    let claudeClient: ClaudeProcessClient

    private func router() -> LLMRouter {
        LLMRouter(
            choice: store.load().llmChoice,
            onDevice: FoundationModelsProvider(client: onDeviceClient),
            claude: ClaudeCodeProvider(generator: claudeClient),
            isOnDeviceAvailable: { onDeviceClient.isAvailable }
        )
    }

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        try await router().buildProfile(fromPortfolio: portfolio)
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        try await router().rank(jobs: jobs, against: profile)
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile) async throws -> ApplicationKit {
        try await router().generateApplication(for: job, profile: profile)
    }
}

/// A `JobSource` that reads the current Adzuna credentials from settings on each search.
private nonisolated struct SettingsBackedJobSource: JobSource {
    let store: SettingsStore
    let http: any HTTPClient

    func search(_ query: JobQuery) async throws -> [JobListing] {
        let source = AdzunaJobSource(credentials: store.load().adzunaCredentials, http: http)
        return try await source.search(query)
    }
}
