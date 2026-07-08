//
//  PreviewSupport.swift
//  Taylor'd Portfolio
//
//  Presentation · App — stub engines + sample data for SwiftUI previews (DEBUG only).
//

#if DEBUG
import Foundation

/// Canned dependencies and sample data so screen `#Preview`s render without real
/// engines, network, or credentials.
enum Preview {

    nonisolated struct StubProvider: LLMProvider {
        func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile { sampleProfile }
        func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
            jobs.map { JobMatch(jobId: $0.id, score: 72, reason: "Solid Swift/SwiftUI overlap.", matchedSkills: ["Swift"], missingSkills: ["Kotlin"]) }
        }
        func generateApplication(for job: JobListing, profile: CandidateProfile) async throws -> ApplicationKit {
            ApplicationKit(
                resumeMarkdown: "# \(profile.seniority) Engineer\n\n- Built native apps for \(job.company).",
                coverLetter: "Dear \(job.company) team,\n\nI'd love to help…",
                gapNote: "No direct Kotlin experience."
            )
        }
    }

    nonisolated struct StubJobSource: JobSource {
        func search(_ query: JobQuery) async throws -> [JobListing] { sampleListings }
    }

    nonisolated final class MemoryStore: KeyValueStore, @unchecked Sendable {
        private var storage: [String: Data] = [:]
        func data(forKey key: String) -> Data? { storage[key] }
        func setData(_ data: Data?, forKey key: String) { storage[key] = data }
    }

    nonisolated struct StubDocumentExtractor: DocumentTextExtractor {
        func extractText(from url: URL) throws -> String { "Imported portfolio text from \(url.lastPathComponent)." }
    }

    static var buildProfile: BuildProfileUseCase { .init(provider: StubProvider()) }
    static var importPortfolio: ImportPortfolioUseCase { .init(extractor: StubDocumentExtractor()) }
    static var searchAndRank: SearchAndRankUseCase {
        .init(jobSource: StubJobSource(), ranker: JobRanker(provider: StubProvider()))
    }
    static var generateApplication: GenerateApplicationUseCase { .init(provider: StubProvider()) }
    static var settingsStore: SettingsStore { .init(store: MemoryStore()) }

    static var sampleProfile: CandidateProfile {
        CandidateProfile(
            seniority: "Senior", yearsExperience: 8, coreSkills: ["Swift", "SwiftUI", "Concurrency"],
            domains: ["Fintech"], targetTitles: ["iOS Engineer"], summary: "Eight years building native Apple apps."
        )
    }

    static var sampleListings: [JobListing] {
        [
            JobListing(id: "1", title: "iOS Engineer", company: "Acme", location: "Remote", description: "Swift + SwiftUI."),
            JobListing(id: "2", title: "Mobile Lead", company: "Globex", location: "New York", description: "Lead a small team."),
        ]
    }

    static var sampleRankedJobs: [RankedJob] {
        sampleListings.enumerated().map { index, listing in
            RankedJob(
                listing: listing,
                match: JobMatch(
                    jobId: listing.id, score: 88 - index * 20, reason: "Strong overlap with your Swift experience.",
                    matchedSkills: ["Swift", "SwiftUI"], missingSkills: ["Kotlin"]
                )
            )
        }
    }
}
#endif
