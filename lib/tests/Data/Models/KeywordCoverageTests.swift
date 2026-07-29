//
//  KeywordCoverageTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Models — posting-keyword coverage of the visible résumé (v0.6.1 Milestone A).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// A brief with only the three keyword tiers filled — the rest is irrelevant to coverage.
private func brief(
    mustHave: [String] = [],
    niceToHave: [String] = [],
    techStack: [String] = []
) -> TargetBrief {
    TargetBrief(
        company: "Acme",
        roleTitle: "iOS Engineer",
        mustHaveKeywords: mustHave,
        niceToHaveKeywords: niceToHave,
        techStack: techStack,
        domain: "Mobile",
        missionValues: ""
    )
}

@Suite("KeywordCoverage")
struct KeywordCoverageTests {

    // MARK: Basic matching

    @Test func findsAKeywordPresentInTheResume() {
        let coverage = KeywordCoverage(mustHave: ["Swift"], niceToHave: [], techStack: [],
                                       resumeText: "Built native apps in Swift.")
        #expect(coverage.mustHave?.covered == ["Swift"])
        #expect(coverage.mustHave?.missing == [])
    }

    @Test func reportsAKeywordAbsentFromTheResume() {
        let coverage = KeywordCoverage(mustHave: ["Kotlin"], niceToHave: [], techStack: [],
                                       resumeText: "Built native apps in Swift.")
        #expect(coverage.mustHave?.covered == [])
        #expect(coverage.mustHave?.missing == ["Kotlin"])
    }

    @Test func matchingIsCaseInsensitive() {
        let coverage = KeywordCoverage(mustHave: ["SWIFTUI"], niceToHave: [], techStack: [],
                                       resumeText: "Shipped a SwiftUI app.")
        #expect(coverage.coveredCount == 1)
    }

    @Test func matchingFoldsDiacritics() {
        #expect(KeywordCoverage.normalized("Café") == KeywordCoverage.normalized("cafe"))
    }

    // MARK: Word boundaries

    @Test func aKeywordInsideALongerWordDoesNotCount() {
        let coverage = KeywordCoverage(
            mustHave: ["Go", "React"], niceToHave: [], techStack: [],
            resumeText: "Deployed on Google Cloud with reactive pipelines."
        )
        #expect(coverage.mustHave?.covered == [])
        #expect(coverage.mustHave?.missing == ["Go", "React"])
    }

    @Test func aBoundedOccurrenceLaterInTheTextStillCounts() {
        // The first "go" sits inside "logo" — the scan must keep looking, not give up.
        #expect(KeywordCoverage.contains("go", in: "logo go"))
        #expect(!KeywordCoverage.contains("go", in: "logo logo"))
    }

    @Test func keywordsEndingInPunctuationMatch() {
        // The case a regex `\b` gets wrong: there is no word character after "C++".
        let coverage = KeywordCoverage(
            mustHave: ["C++", "C#"], niceToHave: [], techStack: [],
            resumeText: "Wrote C++ services and a C# tool."
        )
        #expect(coverage.mustHave?.covered == ["C++", "C#"])
    }

    @Test func keywordsWithLeadingOrInternalPunctuationMatch() {
        let coverage = KeywordCoverage(
            mustHave: [".NET", "Node.js"], niceToHave: [], techStack: [],
            resumeText: "Maintained .NET Core services alongside a Node.js gateway."
        )
        #expect(coverage.mustHave?.missing == [])
    }

    @Test func trailingSentencePunctuationOnAKeywordIsIgnored() {
        let coverage = KeywordCoverage(mustHave: ["Swift,"], niceToHave: [], techStack: [],
                                       resumeText: "Ten years of Swift.")
        #expect(coverage.coveredCount == 1)
    }

    // MARK: Phrases

    @Test func multiWordKeywordsMatchAsPhrases() {
        let coverage = KeywordCoverage(mustHave: ["REST APIs"], niceToHave: [], techStack: [],
                                       resumeText: "Designed REST APIs for partner integrations.")
        #expect(coverage.coveredCount == 1)
    }

    @Test func aPhraseMatchesAcrossALineBreak() {
        let coverage = KeywordCoverage(mustHave: ["REST APIs"], niceToHave: [], techStack: [],
                                       resumeText: "Designed REST\n   APIs for partners.")
        #expect(coverage.coveredCount == 1)
    }

    @Test func aPhraseWhoseWordsAreScatteredDoesNotCount() {
        let coverage = KeywordCoverage(mustHave: ["REST APIs"], niceToHave: [], techStack: [],
                                       resumeText: "Built APIs. Comfortable with REST.")
        #expect(coverage.coveredCount == 0)
    }

    @Test func matchingDoesNotStem() {
        // Light normalization only — over-matching would report coverage the user lacks.
        let coverage = KeywordCoverage(mustHave: ["management"], niceToHave: [], techStack: [],
                                       resumeText: "Managed a team of six.")
        #expect(coverage.coveredCount == 0)
    }

    // MARK: Markdown reduction

    @Test func keywordsBehindMarkdownSyntaxCount() {
        let markdown = """
        ## Skills
        - **SwiftUI**, *Combine*, and `async/await`
        - [Kubernetes](https://example.com) in production
        """
        let coverage = KeywordCoverage(
            brief: brief(mustHave: ["SwiftUI", "Combine", "Kubernetes"]),
            resumeMarkdown: markdown
        )
        #expect(coverage.mustHave?.missing == [])
        #expect(coverage.coveredCount == 3)
    }

    @Test func aKeywordThatIsOnlyAMarkdownLinkTargetDoesNotCount() {
        // The URL is stripped with the syntax — it was never visible text.
        let coverage = KeywordCoverage(
            brief: brief(mustHave: ["terraform"]),
            resumeMarkdown: "See [my infra work](https://terraform.example.com)."
        )
        #expect(coverage.coveredCount == 0)
    }

    // MARK: Tiers, de-duplication, and roll-ups

    @Test func tiersAreReportedInPriorityOrder() {
        let coverage = KeywordCoverage(
            brief: brief(mustHave: ["Swift"], niceToHave: ["Metal"], techStack: ["Xcode"]),
            resumeMarkdown: "Swift and Xcode."
        )
        #expect(coverage.tiers.map(\.tier) == [.mustHave, .niceToHave, .techStack])
    }

    @Test func aTierWithNoUsableKeywordsIsOmitted() {
        let coverage = KeywordCoverage(mustHave: ["Swift"], niceToHave: [], techStack: ["  "],
                                       resumeText: "Swift.")
        #expect(coverage.tiers.map(\.tier) == [.mustHave])
    }

    @Test func aKeywordRepeatedAcrossTiersIsCountedOnceInItsHighestTier() {
        let coverage = KeywordCoverage(mustHave: ["Swift"], niceToHave: ["swift"], techStack: ["Swift"],
                                       resumeText: "Ten years of Swift.")
        #expect(coverage.tiers.map(\.tier) == [.mustHave])
        #expect(coverage.allTotalCount == 1)
    }

    @Test func duplicatesWithinATierAreCountedOnce() {
        let coverage = KeywordCoverage(mustHave: ["Swift", "swift "], niceToHave: [], techStack: [],
                                       resumeText: "Swift.")
        #expect(coverage.totalCount == 1)
    }

    @Test func theHeadlineCountsMustHavesWhileTheBreakdownKeepsEveryTier() {
        let coverage = KeywordCoverage(
            mustHave: ["Swift", "Kotlin"], niceToHave: ["Metal", "Vision"], techStack: ["Xcode"],
            resumeText: "Swift, Metal, Vision, and Xcode."
        )
        #expect(coverage.coveredCount == 1)
        #expect(coverage.totalCount == 2)
        #expect(coverage.allCoveredCount == 4)
        #expect(coverage.allTotalCount == 5)
    }

    // MARK: Empty edges

    @Test func aPostingWithNoKeywordsIsEmpty() {
        let coverage = KeywordCoverage(brief: brief(), resumeMarkdown: "Swift, Metal, Xcode.")
        #expect(coverage.isEmpty)
        #expect(coverage.coveredCount == 0)
        #expect(coverage.totalCount == 0)
    }

    @Test func blankKeywordsAreDroppedRatherThanCountedMissing() {
        let coverage = KeywordCoverage(mustHave: ["Swift", "", "   ", "\n"], niceToHave: [], techStack: [],
                                       resumeText: "Swift.")
        #expect(coverage.totalCount == 1)
        #expect(coverage.mustHave?.missing == [])
    }

    @Test func anEmptyResumeMissesEverything() {
        let coverage = KeywordCoverage(mustHave: ["Swift", "Kotlin"], niceToHave: [], techStack: [],
                                       resumeText: "")
        #expect(coverage.mustHave?.missing == ["Swift", "Kotlin"])
        #expect(coverage.coveredCount == 0)
        #expect(!coverage.isEmpty)
    }

    @Test func keywordsAreReportedAsThePostingWroteThem() {
        let coverage = KeywordCoverage(mustHave: ["  C++  "], niceToHave: [], techStack: [],
                                       resumeText: "Wrote C++ services.")
        #expect(coverage.mustHave?.covered == ["C++"])
    }
}
