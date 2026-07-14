//
//  ClaudeCodeProviderTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · LLM — ClaudeCodeProvider decodes JSON from a stubbed engine.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// A `TextGenerating` stub that returns canned text and records how it was called.
private actor RecordingGenerator: TextGenerating {
    private var responses: [String]
    private(set) var calls: [(prompt: String, instructions: String?)] = []

    init(_ response: String) { self.responses = [response] }

    func generate(prompt: String, instructions: String?) async throws -> String {
        calls.append((prompt, instructions))
        return responses.first ?? ""
    }
}

@Suite("ClaudeCodeProvider")
struct ClaudeCodeProviderTests {

    private let sampleProfile = CandidateProfile(
        seniority: "Senior", yearsExperience: 8, coreSkills: ["Swift"],
        domains: ["Fintech"], targetTitles: ["iOS Engineer"], summary: "Hi."
    )
    private let sampleJob = JobListing(
        id: "a", title: "iOS Engineer", company: "Acme", location: "Remote", description: "desc"
    )

    @Test func buildProfileDecodesAndComposesPrompt() async throws {
        let json = #"{"seniority":"Senior","yearsExperience":8,"coreSkills":["Swift"],"domains":["Fintech"],"targetTitles":["iOS Engineer"],"summary":"Hi."}"#
        let gen = RecordingGenerator(json)
        let provider = ClaudeCodeProvider(generator: gen)

        let profile = try await provider.buildProfile(fromPortfolio: "MY_PORTFOLIO_TEXT")
        #expect(profile.seniority == "Senior")
        #expect(profile.yearsExperience == 8)

        let calls = await gen.calls
        #expect(calls.count == 1)
        #expect(calls[0].instructions == Prompts.profileInstructions)
        #expect(calls[0].prompt.contains("MY_PORTFOLIO_TEXT"))
        #expect(calls[0].prompt.contains(Prompts.jsonOnlySuffix))
    }

    @Test func rankDecodesMatchesArray() async throws {
        let json = #"{"matches":[{"jobId":"a","score":90,"reason":"good","matchedSkills":["Swift"],"missingSkills":[]}]}"#
        let provider = ClaudeCodeProvider(generator: RecordingGenerator(json))

        let matches = try await provider.rank(jobs: [sampleJob], against: sampleProfile)
        #expect(matches.count == 1)
        #expect(matches[0].jobId == "a")
        #expect(matches[0].score == 90)
    }

    @Test func buildTargetBriefDecodesAndComposesPrompt() async throws {
        let json = #"{"company":"Acme","roleTitle":"iOS Engineer","mustHaveKeywords":["Swift"],"niceToHaveKeywords":["Kotlin"],"techStack":["SwiftUI"],"domain":"Mobile","missionValues":"Delight users."}"#
        let gen = RecordingGenerator(json)
        let provider = ClaudeCodeProvider(generator: gen)

        let brief = try await provider.buildTargetBrief(for: sampleJob)
        #expect(brief.company == "Acme")
        #expect(brief.roleTitle == "iOS Engineer")
        #expect(brief.mustHaveKeywords == ["Swift"])

        let calls = await gen.calls
        #expect(calls[0].instructions == Prompts.briefInstructions)
        #expect(calls[0].prompt.contains(Prompts.jsonOnlySuffix))
    }

    @Test func generateApplicationDecodes() async throws {
        let json = ##"{"resumeMarkdown":"# Resume","coverLetter":"Dear team","gapNote":"none"}"##
        let gen = RecordingGenerator(json)
        let provider = ClaudeCodeProvider(generator: gen)
        let brief = TargetBrief(company: "Acme", roleTitle: "iOS Engineer", mustHaveKeywords: ["Swift"],
                                niceToHaveKeywords: [], techStack: ["SwiftUI"], domain: "Mobile", missionValues: "")

        let kit = try await provider.generateApplication(for: sampleJob, profile: sampleProfile, brief: brief)
        #expect(kit.resumeMarkdown == "# Resume")
        #expect(kit.coverLetter == "Dear team")

        // The stage-1 brief must reach the generation prompt.
        let prompt = await gen.calls[0].prompt
        #expect(prompt.contains("iOS Engineer"))
        #expect(prompt.contains("## Why Acme"))
    }

    @Test func rankOneDecodesASingleMatchAndCarriesGuidance() async throws {
        let json = #"{"jobId":"j9","score":72,"reason":"strong","matchedSkills":["Swift"],"missingSkills":[]}"#
        let gen = RecordingGenerator(json)
        let provider = ClaudeCodeProvider(generator: gen)

        let match = try await provider.rank(job: sampleJob, against: sampleProfile, instruction: "WEIGHT_GO")
        #expect(match.jobId == "j9")
        #expect(match.score == 72)

        let calls = await gen.calls
        #expect(calls[0].instructions == Prompts.rankInstructions)
        #expect(calls[0].prompt.contains("WEIGHT_GO"))
        #expect(calls[0].prompt.contains(Prompts.jsonOnlySuffix))
    }

    @Test func enrichPostingDecodesPostingDetails() async throws {
        let json = ##"{"workTypeRaw":"remote","qualifications":["5+ years Swift"],"responsibilities":["Ship features"],"niceToHaves":["Kotlin"],"aboutRole":"Build the app.","aboutCompany":"We do fintech.","benefits":["Health"]}"##
        let gen = RecordingGenerator(json)
        let provider = ClaudeCodeProvider(generator: gen)

        let details = try await provider.enrichPosting(fromPostingText: "SEED_POSTING")
        #expect(details.workType == .remote)
        #expect(details.qualifications == ["5+ years Swift"])
        #expect(details.aboutCompany == "We do fintech.")
        #expect(details.hasContent)

        let calls = await gen.calls
        #expect(calls[0].instructions == Prompts.enrichInstructions)
        #expect(calls[0].prompt.contains("SEED_POSTING"))
        #expect(calls[0].prompt.contains(Prompts.jsonOnlySuffix))
    }

    @Test func tidyDocumentReturnsRawTextWithoutJSONEnvelope() async throws {
        let gen = RecordingGenerator("Cleaned up resume text.")
        let provider = ClaudeCodeProvider(generator: gen)

        let tidied = try await provider.tidyDocument(rawText: "MESSY\nPDF   TEXT")
        #expect(tidied == "Cleaned up resume text.")   // returned verbatim, not JSON-decoded

        let calls = await gen.calls
        #expect(calls[0].instructions == Prompts.tidyInstructions)
        #expect(calls[0].prompt.contains("MESSY"))
        #expect(!calls[0].prompt.contains(Prompts.jsonOnlySuffix))   // plain-text task
    }

    @Test func invalidJSONThrowsDecodingFailed() async {
        let provider = ClaudeCodeProvider(generator: RecordingGenerator("not json at all"))
        await #expect(throws: LLMProviderError.decodingFailed("not json at all")) {
            _ = try await provider.buildProfile(fromPortfolio: "x")
        }
    }
}
