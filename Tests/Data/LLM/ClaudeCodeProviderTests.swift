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

    @Test func generateApplicationDecodes() async throws {
        let json = ##"{"resumeMarkdown":"# Resume","coverLetter":"Dear team","gapNote":"none"}"##
        let provider = ClaudeCodeProvider(generator: RecordingGenerator(json))

        let kit = try await provider.generateApplication(for: sampleJob, profile: sampleProfile)
        #expect(kit.resumeMarkdown == "# Resume")
        #expect(kit.coverLetter == "Dear team")
    }

    @Test func invalidJSONThrowsDecodingFailed() async {
        let provider = ClaudeCodeProvider(generator: RecordingGenerator("not json at all"))
        await #expect(throws: LLMProviderError.decodingFailed("not json at all")) {
            _ = try await provider.buildProfile(fromPortfolio: "x")
        }
    }
}
