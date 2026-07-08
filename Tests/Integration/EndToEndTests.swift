//
//  EndToEndTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Integration — the full vertical slice through real ViewModels + use cases,
//  with stub engines standing in for the on-device model / Claude / Adzuna.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@MainActor
@Suite("End-to-end vertical slice")
struct EndToEndTests {

    /// Portfolio → profile → search → ranked results → generated application, driving
    /// the same ViewModels and use cases the app wires together in `Composition`.
    @Test func fullFlowFromPortfolioToApplication() async throws {
        let provider = PresentationStubProvider(
            profileSeniority: "Senior",
            matches: [JobMatch(jobId: "1", score: 88, reason: "Strong Swift fit.", matchedSkills: ["Swift"], missingSkills: [])],
            kitResume: "# Senior Engineer"
        )
        let jobs = [JobListing(id: "1", title: "iOS Engineer", company: "Acme", location: "Remote", description: "Swift + SwiftUI")]

        let buildProfile = BuildProfileUseCase(provider: provider)
        let importPortfolio = ImportPortfolioUseCase(extractor: PresentationStubExtractor())
        let searchAndRank = SearchAndRankUseCase(
            jobSource: PresentationStubJobSource(jobs: jobs),
            ranker: JobRanker(provider: provider)
        )
        let generateApplication = GenerateApplicationUseCase(provider: provider)

        // 1. Portfolio → profile
        let portfolio = PortfolioViewModel(buildProfile: buildProfile, importPortfolio: importPortfolio)
        portfolio.portfolioText = "Eight years of Swift and SwiftUI."
        await portfolio.build()
        let profile = try #require(portfolio.profile)
        #expect(profile.seniority == "Senior")

        // 2. Search + rank against that profile
        let search = SearchViewModel(
            searchAndRank: searchAndRank,
            roleTitleStore: RoleTitleStore(store: PresentationMemoryStore())
        )
        search.profile = profile
        search.titleInput = "iOS engineer"
        await search.search()
        let ranked = try #require(search.results.first)
        #expect(search.results.count == 1)
        #expect(ranked.id == "1")
        #expect(ranked.score == 88)

        // 3. Pick a result
        let results = ResultsViewModel(results: search.results)
        results.select(ranked)
        #expect(results.selectedJob?.id == "1")

        // 4. Generate the application for the picked job
        let application = ApplicationViewModel(generateApplication: generateApplication)
        await application.generate(for: ranked.listing, profile: profile)
        let kit = try #require(application.kit)
        #expect(kit.resumeMarkdown.contains("Senior Engineer"))
    }

    /// The alternate input path: import a document, then build the profile from it.
    @Test func importDocumentThenBuildProfile() async throws {
        let provider = PresentationStubProvider(profileSeniority: "Staff")
        let portfolio = PortfolioViewModel(
            buildProfile: BuildProfileUseCase(provider: provider),
            importPortfolio: ImportPortfolioUseCase(extractor: PresentationStubExtractor(text: "Extracted resume text"))
        )

        await portfolio.importDocument(from: URL(fileURLWithPath: "/tmp/resume.pdf"))
        #expect(portfolio.portfolioText == "Extracted resume text")

        await portfolio.build()
        #expect(portfolio.profile?.seniority == "Staff")
    }
}
