//
//  PresentationTestSupport.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation — shared stubs for ViewModel tests.
//

import Foundation
@testable import Taylor_d_Portfolio

/// A configurable `LLMProvider` stub for ViewModel tests.
struct PresentationStubProvider: LLMProvider {
    var profileSeniority = "BUILT"
    var matches: [JobMatch] = []
    var kitResume = "RESUME"
    var shouldThrow = false

    struct Boom: Error {}

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        if shouldThrow { throw Boom() }
        return CandidateProfile(seniority: profileSeniority, yearsExperience: 1, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        if shouldThrow { throw Boom() }
        return matches
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile) async throws -> ApplicationKit {
        if shouldThrow { throw Boom() }
        return ApplicationKit(resumeMarkdown: kitResume, coverLetter: "", gapNote: "")
    }
}

/// A `JobSource` stub returning canned listings.
struct PresentationStubJobSource: JobSource {
    var jobs: [JobListing] = []
    func search(_ query: JobQuery) async throws -> [JobListing] { jobs }
}

/// An in-memory `KeyValueStore` for settings tests.
final class PresentationMemoryStore: KeyValueStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    func data(forKey key: String) -> Data? { storage[key] }
    func setData(_ data: Data?, forKey key: String) { storage[key] = data }
}

/// A `DocumentTextExtractor` stub returning canned text or throwing.
struct PresentationStubExtractor: DocumentTextExtractor {
    var text = "IMPORTED"
    var shouldThrow = false
    func extractText(from url: URL) throws -> String {
        if shouldThrow { throw DocumentExtractionError.readFailed("stub") }
        return text
    }
}
