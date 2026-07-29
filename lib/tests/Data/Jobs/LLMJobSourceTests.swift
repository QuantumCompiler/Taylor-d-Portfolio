//
//  LLMJobSourceTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Jobs — the LLM-backed job source (v0.6.0 Milestone J).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// An `LLMProvider` that returns canned leads and records the grounding it was handed.
private final class LeadStubProvider: LLMProvider, @unchecked Sendable {
    let leads: [GeneratedJobLead]
    private let lock = NSLock()
    private var _sawGrounding: PortfolioGrounding?
    var sawGrounding: PortfolioGrounding? { lock.withLock { _sawGrounding } }

    init(leads: [GeneratedJobLead]) { self.leads = leads }

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        .init(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { [] }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        .init(company: "", roleTitle: "", mustHaveKeywords: [], niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        .init(resumeMarkdown: "", coverLetter: "", gapNote: "")
    }
    func searchJobs(query: JobQuery, grounding: PortfolioGrounding?) async throws -> [GeneratedJobLead] {
        lock.withLock { _sawGrounding = grounding }
        return leads
    }
}

/// A `JobSource` returning canned listings (a stand-in for an API provider in dedup tests).
private struct FixedJobSource: JobSource {
    let listings: [JobListing]
    func search(_ query: JobQuery) async throws -> [JobListing] { listings }
}

@Suite("LLMJobSource")
struct LLMJobSourceTests {
    private func lead(_ title: String, _ company: String, _ location: String = "Remote") -> GeneratedJobLead {
        GeneratedJobLead(title: title, company: company, location: location, summary: "Why it fits.")
    }
    private let query = JobQuery(keywords: "iOS Engineer")

    @Test func mapsLeadsToAITaggedListings() async throws {
        let source = LLMJobSource(provider: LeadStubProvider(leads: [lead("iOS Engineer", "Globex")]))
        let results = try await source.search(query)

        let listing = try #require(results.first)
        #expect(listing.isAISuggested)
        #expect(listing.source == JobListing.aiSource)
        #expect(listing.title == "iOS Engineer")
        #expect(listing.company == "Globex")
        #expect(listing.description == "Why it fits.")   // the lead summary becomes the description
    }

    @Test func urlIsASearchQueryNotAFabricatedPosting() async throws {
        let source = LLMJobSource(provider: LeadStubProvider(leads: [lead("Staff iOS Engineer", "Globex", "Berlin")]))
        let listing = try #require(try await source.search(query).first)
        let url = try #require(listing.url)
        #expect(url.host == "www.google.com")            // a search link, not a posting URL
        #expect(url.path == "/search")
        #expect(url.query?.contains("Globex") == true)
    }

    @Test func idIsDeterministicForDedup() async throws {
        // Two identical leads → identical ids, so re-runs and persistence stay stable.
        let a = LLMJobSource.listing(from: lead("iOS Engineer", "Globex"))
        let b = LLMJobSource.listing(from: lead("iOS Engineer", "Globex"))
        #expect(a.id == b.id)
        #expect(a.id.hasPrefix("ai:"))
    }

    @Test func llmLeadDedupsAgainstAnAPIListingByFingerprint() async throws {
        // An API posting and an AI lead for the same role share a fingerprint, so the composite
        // keeps one — the API source (listed first) wins over the AI dupe.
        let apiListing = JobListing(id: "adzuna-1", title: "iOS Engineer", company: "Globex", location: "Remote", description: "real", source: "Adzuna")
        let composite = CompositeJobSource(sources: [
            FixedJobSource(listings: [apiListing]),
            LLMJobSource(provider: LeadStubProvider(leads: [lead("iOS Engineer", "Globex")])),
        ])
        let results = try await composite.search(JobQuery(keywords: "iOS"))
        #expect(results.count == 1)
        #expect(results.first?.source == "Adzuna")       // verified posting kept over the AI dupe
    }

    @Test func passesTheGroundingFromTheClosure() async throws {
        let provider = LeadStubProvider(leads: [lead("iOS Engineer", "Globex")])
        let grounding = PortfolioGrounding(resumeText: "MY REAL RESUME")
        let source = LLMJobSource(provider: provider, grounding: { grounding })
        _ = try await source.search(query)
        #expect(provider.sawGrounding?.resumeText == "MY REAL RESUME")
    }

    @Test func emptyLeadsReturnEmpty() async throws {
        let source = LLMJobSource(provider: LeadStubProvider(leads: []))
        #expect(try await source.search(query).isEmpty)
    }
}
