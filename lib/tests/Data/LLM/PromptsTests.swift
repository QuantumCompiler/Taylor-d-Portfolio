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

    // MARK: Enrich posting (v0.6.0 Milestone A-B)

    @Test func enrichPostingPromptAsksForFieldsAndIncludesPostingText() {
        let prompt = Prompts.enrichPosting(postingText: "SEED_POSTING_TEXT")
        #expect(prompt.contains("SEED_POSTING_TEXT"))
        #expect(prompt.contains("workTypeRaw"))
        #expect(prompt.contains("qualifications"))
        #expect(prompt.contains("responsibilities"))
        #expect(prompt.contains("aboutCompany"))
        #expect(prompt.contains("benefits"))
    }

    @Test func enrichPostingBoundsLongText() {
        let huge = String(repeating: "z", count: Prompts.maxPageCharacters + 1_000)
        let prompt = Prompts.enrichPosting(postingText: huge)
        #expect(!prompt.contains(huge))
        #expect(prompt.contains("…"))
    }

    @Test func enrichInstructionsForbidInvention() {
        #expect(Prompts.enrichInstructions.lowercased().contains("never invent"))
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

    // MARK: Enriched posting detail in the brief (v0.6.0 Milestone A-E)

    @Test func briefPromptIncludesEnrichedPostingDetailWhenPresent() {
        let details = PostingDetails(
            workTypeRaw: "remote",
            qualifications: ["5+ years Swift"],
            responsibilities: ["Ship features"],
            niceToHaves: ["Kotlin"],
            aboutRole: "Own the iOS app.",
            aboutCompany: "We build fintech.",
            benefits: ["Health"]
        )
        let job = JobListing(id: "a", title: "iOS", company: "Acme", location: "Remote", description: "SEED_DESC", details: details)
        let prompt = Prompts.buildTargetBrief(job: job)
        #expect(prompt.contains("Structured posting detail"))
        #expect(prompt.contains("Remote"))              // workType label
        #expect(prompt.contains("5+ years Swift"))       // qualifications
        #expect(prompt.contains("We build fintech."))    // aboutCompany
        #expect(prompt.contains("Health"))               // benefits
    }

    @Test func briefPromptIsUnchangedWithoutDetails() {
        // The pre-A-E path stays byte-for-byte: no detail block when details is nil.
        let job = JobListing(id: "a", title: "iOS", company: "Acme", location: "Remote", description: "SEED_DESC")
        let prompt = Prompts.buildTargetBrief(job: job)
        #expect(!prompt.contains("Structured posting detail"))
    }

    @Test func postingDetailSectionOmitsEmptyFieldsAndEmptyDetails() {
        // Empty details → "", so the brief prompt is unchanged.
        #expect(Prompts.postingDetailSection(nil).isEmpty)
        #expect(Prompts.postingDetailSection(PostingDetails()).isEmpty)
        // Only the present fields are rendered — a work-type-only detail lists just that.
        let onlyWork = PostingDetails(workTypeRaw: "hybrid")
        let section = Prompts.postingDetailSection(onlyWork)
        #expect(section.contains("workType: Hybrid"))
        #expect(!section.contains("qualifications"))
        #expect(!section.contains("aboutCompany"))
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

    // MARK: T-B — two-document grounding

    private var job: JobListing {
        JobListing(id: "a", title: "iOS Engineer", company: "Acme", location: "Remote", description: "d")
    }

    @Test func nilGroundingLeavesThePromptUnchanged() {
        let base = Prompts.generateApplication(job: job, profile: sampleProfile, brief: sampleBrief)
        let withNil = Prompts.generateApplication(job: job, profile: sampleProfile, brief: sampleBrief, grounding: nil)
        #expect(base == withNil)   // back-compat: profile-only generation is byte-for-byte the same
    }

    @Test func resumeGroundingIsInjectedAsFactualGrounding() {
        let grounding = PortfolioGrounding(resumeText: "REAL RESUME with QuantumKit at Globex")
        let prompt = Prompts.generateApplication(job: job, profile: sampleProfile, brief: sampleBrief, grounding: grounding)
        #expect(prompt.contains("REAL RESUME with QuantumKit at Globex"))
        #expect(prompt.lowercased().contains("résumé"))
        #expect(prompt.contains("factual grounding"))
    }

    @Test func coverLetterIsAVoiceExemplarWithANoFabricationGuardrail() {
        let grounding = PortfolioGrounding(resumeText: "resume", coverLetterText: "Dear team, my authentic voice.")
        let prompt = Prompts.generateApplication(job: job, profile: sampleProfile, brief: sampleBrief, grounding: grounding)
        #expect(prompt.contains("Dear team, my authentic voice."))
        #expect(prompt.lowercased().contains("voice"))
        // The guardrail: match the voice, but never import facts from the letter.
        #expect(prompt.lowercased().contains("do not import"))
    }

    @Test func absentCoverLetterOmitsTheVoiceSectionCleanly() {
        let resumeOnly = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            grounding: PortfolioGrounding(resumeText: "resume", coverLetterText: nil)
        )
        #expect(resumeOnly.contains("factual grounding"))
        #expect(!resumeOnly.lowercased().contains("style example"))   // no cover-letter block
    }

    // MARK: Refine summary

    @Test func refineSummaryPromptCarriesInstructionProfileAndPortfolio() {
        let prompt = Prompts.refineSummary(
            profile: sampleProfile, portfolio: "REAL PORTFOLIO with Globex", instruction: "emphasise leadership"
        )
        #expect(prompt.contains("emphasise leadership"))    // the user instruction
        #expect(prompt.contains("Senior"))                  // profile facts
        #expect(prompt.contains("REAL PORTFOLIO with Globex"))
        #expect(prompt.lowercased().contains("only the rewritten summary"))
        #expect(Prompts.refineSummaryInstructions.lowercased().contains("never invent"))
    }

    @Test func refineSummaryWithEmptyInstructionAsksForAFreshSummary() {
        let prompt = Prompts.refineSummary(profile: sampleProfile, portfolio: "", instruction: "   ")
        #expect(prompt.lowercased().contains("fresh"))
        #expect(!prompt.contains("Portfolio (the candidate's real experience"))   // empty portfolio omitted
    }

    @Test func refineSummaryBoundsALongPortfolio() {
        let long = String(repeating: "P", count: Prompts.maxPortfolioCharacters + 500)
        let prompt = Prompts.refineSummary(profile: sampleProfile, portfolio: long, instruction: "x")
        #expect(!prompt.contains(long))
        #expect(prompt.contains("…"))
    }

    @Test func groundingDocumentsAreBounded() {
        let longResume = String(repeating: "R", count: Prompts.maxPortfolioCharacters + 500)
        let longLetter = String(repeating: "L", count: Prompts.maxCoverLetterCharacters + 500)
        let prompt = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            grounding: PortfolioGrounding(resumeText: longResume, coverLetterText: longLetter)
        )
        #expect(!prompt.contains(longResume))   // truncated, not injected whole
        #expect(!prompt.contains(longLetter))
        #expect(prompt.contains("…"))
    }

    // MARK: D — generation controls (fidelity / aspects / disclosure)

    @Test func defaultSettingsLeaveThePromptUnchanged() {
        let base = Prompts.generateApplication(job: job, profile: sampleProfile, brief: sampleBrief)
        let withDefault = Prompts.generateApplication(job: job, profile: sampleProfile, brief: sampleBrief, settings: .default)
        #expect(base == withDefault)   // grounded default path is byte-for-byte unchanged
        #expect(!withDefault.contains("GENERATION CONTROLS"))
    }

    @Test func curatedFidelityAppendsALatitudeClause() {
        let prompt = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            settings: GenerationSettings(fidelity: 0.5)
        )
        #expect(prompt.contains("GENERATION CONTROLS"))
        #expect(prompt.lowercased().contains("curate"))
        #expect(prompt.contains("Scope: tailor all"))
        #expect(!prompt.contains("EMBELLISHED:"))   // no disclosure clause below the embellished band
    }

    @Test func embellishedFidelityRequiresDisclosure() {
        let prompt = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            settings: GenerationSettings(fidelity: 1.0)
        )
        #expect(prompt.contains("plausible embellishments"))
        #expect(prompt.contains("Disclosure (REQUIRED)"))
        #expect(prompt.contains("EMBELLISHED:"))
    }

    @Test func selectedAspectsRestrictTheScope() {
        let prompt = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            settings: GenerationSettings(fidelity: 0.5, aspects: [.summary, .skills])
        )
        #expect(prompt.contains("tailor ONLY these"))
        #expect(prompt.contains("Summary / Headline"))
        #expect(prompt.contains("Skills"))
        #expect(prompt.contains("Reproduce every other section"))
    }

    @Test func tailoringNamesTheKeywordMatchingGoalAndCoverLetterFollowsResume() {
        let prompt = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            settings: GenerationSettings(fidelity: 0.5, aspects: [.experience])
        )
        // D-C: every targeted section aims at the job post's keywords + description.
        #expect(prompt.contains("MATCH THIS JOB POST'S keywords"))
        // D-C: the cover letter is derived from the tailored résumé, not tailored on its own.
        #expect(prompt.contains("write it FROM the tailored"))
    }

    @Test func tailoredAspectsAreTheFourResumeSectionsOnly() {
        let cases = Set(TailoredAspect.allCases.map(\.rawValue))
        #expect(cases == ["summary", "experience", "projects", "skills"])
        #expect(!cases.contains("education"))
        #expect(!cases.contains("coverLetter"))
    }

    // MARK: I — additional user guidance (free-text steering)

    @Test func additionalContextIsInjectedAsSteeringGuidance() {
        let prompt = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            settings: GenerationSettings(additionalContext: "lean into the API-gateway angle")
        )
        #expect(prompt.contains("ADDITIONAL USER GUIDANCE"))
        #expect(prompt.contains("lean into the API-gateway angle"))
        #expect(prompt.contains("does NOT permit inventing"))   // the framing-not-facts guardrail
    }

    @Test func emptyAdditionalContextLeavesThePromptUnchanged() {
        let base = Prompts.generateApplication(job: job, profile: sampleProfile, brief: sampleBrief)
        let blank = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            settings: GenerationSettings(additionalContext: "   ")
        )
        #expect(base == blank)   // blank/whitespace guidance is byte-for-byte the base prompt
        #expect(!blank.contains("ADDITIONAL USER GUIDANCE"))
    }

    @Test func contextOnlyAddsGuidanceButNotTheFidelityControls() {
        // Context set but fidelity/aspects/target at default → the guidance appears, but the
        // GENERATION CONTROLS latitude/scope block does not.
        let prompt = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            settings: GenerationSettings(additionalContext: "focus on leadership")
        )
        #expect(prompt.contains("ADDITIONAL USER GUIDANCE"))
        #expect(prompt.contains("focus on leadership"))
        #expect(!prompt.contains("GENERATION CONTROLS"))
    }

    @Test func additionalContextIsBounded() {
        let long = String(repeating: "C", count: Prompts.maxAdditionalContextCharacters + 500)
        let prompt = Prompts.generateApplication(
            job: job, profile: sampleProfile, brief: sampleBrief,
            settings: GenerationSettings(additionalContext: long)
        )
        #expect(!prompt.contains(long))
        #expect(prompt.contains("…"))
    }
}
