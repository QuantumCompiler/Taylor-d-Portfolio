//
//  LLMRouter.swift
//  Taylor'd Portfolio
//
//  Data · LLM — picks an engine per LLMChoice, with auto-fallback.
//

import Foundation

/// Routes each LLM task to an engine according to ``LLMChoice``, and itself conforms
/// to `LLMProvider` so callers depend on one seam.
///
/// - `.onDevice` / `.claude` use exactly that engine.
/// - `.auto` prefers on-device (when available) and falls back to Claude if the
///   on-device engine is unavailable *or* a call throws.
nonisolated struct LLMRouter: LLMProvider {
    let choice: LLMChoice
    let onDevice: any LLMProvider
    let claude: any LLMProvider
    /// Whether the on-device engine is usable right now (checked for `.auto`).
    let isOnDeviceAvailable: @Sendable () -> Bool

    init(
        choice: LLMChoice,
        onDevice: any LLMProvider,
        claude: any LLMProvider,
        isOnDeviceAvailable: @escaping @Sendable () -> Bool
    ) {
        self.choice = choice
        self.onDevice = onDevice
        self.claude = claude
        self.isOnDeviceAvailable = isOnDeviceAvailable
    }

    // MARK: LLMProvider

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        try await run { try await $0.buildProfile(fromPortfolio: portfolio) }
    }

    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        try await run { try await $0.rank(jobs: jobs, against: profile) }
    }

    func extractPosting(fromPageText pageText: String) async throws -> ExtractedPosting {
        try await run { try await $0.extractPosting(fromPageText: pageText) }
    }

    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        try await run { try await $0.buildTargetBrief(for: job) }
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        try await run { try await $0.generateApplication(for: job, profile: profile, brief: brief) }
    }

    // MARK: Routing

    /// The engines to try, in order, for the current choice.
    private func providerOrder() -> [any LLMProvider] {
        switch choice {
        case .onDevice:
            return [onDevice]
        case .claude:
            return [claude]
        case .auto:
            return isOnDeviceAvailable() ? [onDevice, claude] : [claude]
        }
    }

    /// Runs `operation` against each engine in order, returning the first success and
    /// falling back on error. Throws the last error if every engine fails.
    private func run<T>(_ operation: (any LLMProvider) async throws -> T) async throws -> T {
        var lastError: Error?
        for provider in providerOrder() {
            do {
                return try await operation(provider)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? LLMProviderError.noProviderAvailable
    }
}
