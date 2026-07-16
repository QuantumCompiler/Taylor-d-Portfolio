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
    /// Canned posting structure returned by `enrichPosting` (Milestone K digest); nil ⇒ throws
    /// (so a digest finds nothing and the listing is left unchanged).
    var enrichDetails: PostingDetails?

    struct Boom: Error {}

    func enrichPosting(fromPostingText postingText: String) async throws -> PostingDetails {
        guard let enrichDetails else { throw Boom() }
        return enrichDetails
    }

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        if shouldThrow { throw Boom() }
        return CandidateProfile(seniority: profileSeniority, yearsExperience: 1, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func tidyDocument(rawText: String) async throws -> String {
        if shouldThrow { throw Boom() }
        return "TIDY:\n" + rawText
    }
    func refineSummary(profile: CandidateProfile, portfolio: String, instruction: String) async throws -> String {
        if shouldThrow { throw Boom() }
        return "REFINED:\(instruction)"
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        if shouldThrow { throw Boom() }
        return matches
    }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        if shouldThrow { throw Boom() }
        return TargetBrief(
            company: job.company, roleTitle: job.title, mustHaveKeywords: [],
            niceToHaveKeywords: [], techStack: [], domain: "", missionValues: ""
        )
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
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
