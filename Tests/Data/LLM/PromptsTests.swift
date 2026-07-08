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

    // MARK: Extract posting

    @Test func extractPostingPromptAsksForFieldsAndIncludesPageText() {
        let prompt = Prompts.extractPosting(pageText: "SEED_PAGE_TEXT")
        #expect(prompt.contains("SEED_PAGE_TEXT"))
        #expect(prompt.contains("title"))
        #expect(prompt.contains("company"))
        #expect(prompt.contains("location"))
        #expect(prompt.contains("description"))
    }

    @Test func extractPostingBoundsLongPages() {
        let huge = String(repeating: "z", count: Prompts.maxPageCharacters + 1_000)
        let prompt = Prompts.extractPosting(pageText: huge)
        #expect(!prompt.contains(huge))
        #expect(prompt.contains("…"))
    }

    @Test func extractInstructionsForbidInvention() {
        #expect(Prompts.extractInstructions.lowercased().contains("never invent"))
    }

    // MARK: Target brief (stage 1)

    @Test func buildTargetBriefPromptAsksForBriefFieldsAndIncludesPosting() {
        let job = JobListing(id: "a", title: "iOS Engineer", company: "Acme", location: "Remote", description: "SEED_DESC")
        let prompt = Prompts.buildTargetBrief(job: job)
        #expect(prompt.contains("SEED_DESC"))
        #expect(prompt.contains("mustHaveKeywords"))
        #expect(prompt.contains("niceToHaveKeywords"))
        #expect(prompt.contains("techStack"))
        #expect(prompt.contains("missionValues"))
    }

    @Test func longDescriptionsAreBoundedInBriefPrompt() {
        let huge = String(repeating: "x", count: Prompts.maxDescriptionCharacters + 500)
        let job = JobListing(id: "a", title: "t", company: "c", location: "l", description: huge)
        let prompt = Prompts.buildTargetBrief(job: job)
        #expect(!prompt.contains(huge))
        #expect(prompt.contains("…"))
    }

    // MARK: Generate application (stage 2)

    private var sampleProfile: CandidateProfile {
        CandidateProfile(seniority: "Senior", yearsExperience: 8, coreSkills: ["Swift"],
                         domains: ["Fintech"], targetTitles: ["iOS Engineer"], summary: "Hi.")
    }
    private var sampleBrief: TargetBrief {
        TargetBrief(company: "Acme", roleTitle: "iOS Engineer", mustHaveKeywords: ["Swift", "SwiftUI"],
                    niceToHaveKeywords: ["Kotlin"], techStack: ["Swift"], domain: "Mobile", missionValues: "Delight users.")
    }

    @Test func generatePromptStructuresTheThreeCoverLetterSections() {
        let job = JobListing(id: "a", title: "iOS Engineer", company: "Acme", location: "Remote", description: "d")
        let prompt = Prompts.generateApplication(job: job, profile: sampleProfile, brief: sampleBrief)
        #expect(prompt.contains("## About Me"))
        #expect(prompt.contains("## Why Acme"))   // company-specific middle section
        #expect(prompt.contains("## Why Me"))
    }

    @Test func generatePromptCarriesBriefSignalsAndTailoringDiscipline() {
        let job = JobListing(id: "a", title: "iOS Engineer", company: "Acme", location: "Remote", description: "d")
        let prompt = Prompts.generateApplication(job: job, profile: sampleProfile, brief: sampleBrief)
        // Brief signals reach the generation prompt.
        #expect(prompt.contains("iOS Engineer"))
        #expect(prompt.contains("SwiftUI"))
        #expect(prompt.contains("Delight users."))
        // The AGENT.md discipline: map-to-truth + gaps + feature the best fit.
        #expect(prompt.contains("GAP"))
        #expect(prompt.lowercased().contains("best-fit"))
        #expect(prompt.contains("resumeMarkdown"))
        #expect(prompt.contains("gapNote"))
    }

    @Test func generateInstructionsForbidFabrication() {
        #expect(Prompts.generateInstructions.lowercased().contains("never"))
    }
}
