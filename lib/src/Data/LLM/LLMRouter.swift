//
//  LLMRouter.swift
//  Taylor'd Portfolio
//
//  Data · LLM — picks an engine per task (LLMTask → TaskEngineConfig), with fallback.
//

import Foundation

/// Routes each LLM task to an engine according to the user's per-task
/// ``TaskEngineConfig``, and itself conforms to `LLMProvider` so callers depend on
/// one seam.
///
/// Every `LLMProvider` method maps to an ``LLMTask``; the router looks up that task's
/// config to decide the engine and — when Claude is involved — which Claude model:
/// - `.onDevice` / `.claude` use exactly that engine.
/// - `.auto` prefers on-device (when available) and falls back to Claude if the
///   on-device engine is unavailable *or* a call throws.
///
/// The Claude provider is built per task via `makeClaude`, so different tasks can run
/// different models within one router.
nonisolated struct LLMRouter: LLMProvider {
    /// Resolves the engine config for a task (typically from `AppSettings`).
    let configFor: @Sendable (LLMTask) -> TaskEngineConfig
    let onDevice: any LLMProvider
    /// Builds a Claude-backed provider for a given model id.
    let makeClaude: @Sendable (String) -> any LLMProvider
    /// Whether the on-device engine is usable right now (checked for `.auto`).
    let isOnDeviceAvailable: @Sendable () -> Bool

    init(
        configFor: @escaping @Sendable (LLMTask) -> TaskEngineConfig,
        onDevice: any LLMProvider,
        makeClaude: @escaping @Sendable (String) -> any LLMProvider,
        isOnDeviceAvailable: @escaping @Sendable () -> Bool
    ) {
        self.configFor = configFor
        self.onDevice = onDevice
        self.makeClaude = makeClaude
        self.isOnDeviceAvailable = isOnDeviceAvailable
    }

    // MARK: LLMProvider

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        try await run(.profile) { try await $0.buildProfile(fromPortfolio: portfolio) }
    }

    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        try await run(.ranking) { try await $0.rank(jobs: jobs, against: profile) }
    }

    func extractPosting(fromPageText pageText: String) async throws -> ExtractedPosting {
        try await run(.extraction) { try await $0.extractPosting(fromPageText: pageText) }
    }

    /// Tidying the source document uses the SAME engine that builds the profile — it's
    /// the reading step for the same portfolio — so it routes through `.profile`.
    func tidyDocument(rawText: String) async throws -> String {
        try await run(.profile) { try await $0.tidyDocument(rawText: rawText) }
    }

    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        try await run(.application) { try await $0.buildTargetBrief(for: job) }
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        try await run(.application) { try await $0.generateApplication(for: job, profile: profile, brief: brief) }
    }

    // MARK: Routing

    /// The engines to try, in order, for `task`'s configured choice.
    private func providerOrder(for task: LLMTask) -> [any LLMProvider] {
        let config = configFor(task)
        let claude = makeClaude(config.claudeModel)
        switch config.choice {
        case .onDevice:
            return [onDevice]
        case .claude:
            return [claude]
        case .auto:
            return isOnDeviceAvailable() ? [onDevice, claude] : [claude]
        }
    }

    /// Runs `operation` against each engine for `task` in order, returning the first
    /// success and falling back on error. Throws the last error if every engine fails.
    private func run<T>(_ task: LLMTask, _ operation: (any LLMProvider) async throws -> T) async throws -> T {
        var lastError: Error?
        for provider in providerOrder(for: task) {
            do {
                return try await operation(provider)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? LLMProviderError.noProviderAvailable
    }
}
