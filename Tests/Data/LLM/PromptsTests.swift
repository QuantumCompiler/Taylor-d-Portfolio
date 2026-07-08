//
//  PromptsTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · LLM — shared prompt building and input bounding.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("Prompts")
struct PromptsTests {

    @Test func truncateLeavesShortTextUnchanged() {
        #expect(Prompts.truncate("hello", to: 10) == "hello")
    }

    @Test func truncateCutsLongTextAndAppendsEllipsis() {
        let long = String(repeating: "a", count: 20)
        let out = Prompts.truncate(long, to: 5)
        #expect(out == "aaaaa…")
        #expect(out.count == 6) // 5 chars + the ellipsis
    }

    @Test func buildProfilePromptIncludesPortfolioAndFieldNames() {
        let prompt = Prompts.buildProfile(portfolio: "MY_PORTFOLIO")
        #expect(prompt.contains("MY_PORTFOLIO"))
        #expect(prompt.contains("seniority"))
        #expect(prompt.contains("targetTitles"))
    }

    @Test func rankPromptListsEveryJobIdAndAsksForMatches() {
        let profile = CandidateProfile(
            seniority: "s", yearsExperience: 1, coreSkills: [],
            domains: [], targetTitles: [], summary: ""
        )
        let jobs = [
            JobListing(id: "JID1", title: "t", company: "c", location: "l", description: "d"),
            JobListing(id: "JID2", title: "t", company: "c", location: "l", description: "d"),
        ]
        let prompt = Prompts.rank(jobs: jobs, profile: profile)
        #expect(prompt.contains("JID1"))
        #expect(prompt.contains("JID2"))
        #expect(prompt.contains("matches"))
    }

    @Test func longDescriptionsAreBoundedInRankPrompt() {
        let profile = CandidateProfile(
            seniority: "s", yearsExperience: 1, coreSkills: [],
            domains: [], targetTitles: [], summary: ""
        )
        let huge = String(repeating: "x", count: Prompts.maxDescriptionCharacters + 500)
        let job = JobListing(id: "a", title: "t", company: "c", location: "l", description: huge)
        let prompt = Prompts.rank(jobs: [job], profile: profile)
        // The full oversized description must not appear verbatim.
        #expect(!prompt.contains(huge))
        #expect(prompt.contains("…"))
    }
}
