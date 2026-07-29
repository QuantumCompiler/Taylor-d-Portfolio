//
//  LaTeXStyleTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Tex — the user-owned LaTeX presentation style (v0.7.0 Milestone A).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("LaTeXStyle")
struct LaTeXStyleTests {

    // MARK: The default style must describe today's output

    /// The whole point of `.default`: it has to name the values `TexDocumentBuilder` currently
    /// hardcodes, so Milestones B and C can replace those literals behind a byte-for-byte
    /// regression. If someone "improves" a default, this test is the alarm.
    @Test func defaultStyleMatchesTheCurrentlyHardcodedPresentation() {
        let style = LaTeXStyle.default

        #expect(style.template == .awesomeCV)
        // The current builder emits no font-family, colour, or paper option at all.
        #expect(style.fontFamily == .templateDefault)
        #expect(style.fontFamily.faceNamePrefix == nil)
        #expect(style.accent == .templateDefault)
        #expect(style.accent.hex == nil)
        #expect(style.pageSize == .templateDefault)
        #expect(style.pageSize.classOption == nil)
        #expect(style.customPreamble == nil)

        // \documentclass[6pt]{Class/Resume} and \documentclass[11pt, a4paper]{Class/CoverLetter}
        #expect(style.fontSizes.classOption(for: .resume) == "6pt")
        #expect(style.fontSizes.classOption(for: .coverLetter) == "11pt")

        // \geometry{left=0.50cm, top=0.50cm, right=0.50cm, bottom=0.75cm, footskip=0.25cm}
        #expect(style.margins.geometryOptions
            == "left=0.50cm, top=0.50cm, right=0.50cm, bottom=0.75cm, footskip=0.25cm")

        // \setlength{\parskip}{1.0em} / \linespread{1.08}
        #expect(style.letterParagraphSkipArgument == "1.0em")
        #expect(style.letterLineSpreadArgument == "1.08")

        #expect(style.sectionOrder == [.education, .experience, .projects, .skills, .other])
        #expect(style.hiddenSections.isEmpty)
    }

    /// The section `\vspace` values the default style produces are the ones the hand-authored
    /// section files used — which `TexDocumentBuilder` hardcoded in `sectionVSpace(_:)` until
    /// v0.7.0 Milestone C moved them here.
    @Test(arguments: [
        ("Education", "-1em"),
        ("Professional Experience", "-1.5em"),
        ("Selected Projects", "-1.5em"),
        ("Technical Skills", "-0.5em"),
        ("Qualifications", "-0.5em"),
        ("Volunteering", "-1em"),
    ])
    func defaultSectionSpacingMatchesTheHandAuthoredResume(title: String, expected: String) {
        #expect(LaTeXStyle.default.sectionVSpace(forSectionTitled: title) == expected)
    }

    /// Ported verbatim from `TexDocumentBuilderTests.canonicalOrderAndSpacingMatchTheManual`, which
    /// asserted these same values against the two statics C deleted. Same expectations, new home —
    /// the coverage moves with the logic rather than disappearing with it.
    @Test func defaultOrderAndSpacingMatchTheHandAuthoredResume() {
        let style = LaTeXStyle.default
        #expect(style.orderIndex(ofSectionTitled: "Education") == 0)
        #expect(style.orderIndex(ofSectionTitled: "Work Experience") == 1)
        #expect(style.orderIndex(ofSectionTitled: "Projects") == 2)
        #expect(style.orderIndex(ofSectionTitled: "Core Skills") == 3)
        #expect(style.orderIndex(ofSectionTitled: "Awards") == 4)
        #expect(style.sectionVSpace(forSectionTitled: "Education") == "-1em")
        #expect(style.sectionVSpace(forSectionTitled: "Experience") == "-1.5em")
        #expect(style.sectionVSpace(forSectionTitled: "Qualifications") == "-0.5em")
    }

    /// **The one deliberate divergence from the pre-v0.7.0 output.** The builder's two classifiers
    /// disagreed with each other: `canonicalOrder(_:)` treated "Employment" / "Work History" as
    /// *experience* (sorting them second), but `sectionVSpace(_:)` didn't list those synonyms, so
    /// they fell through to the generic `-1em` — an experience section that sorted as experience yet
    /// was spaced as "other". A style has **one** bucket per section, so the bucket wins and those
    /// titles pick up the experience spacing. The effect on the **emitted document** is pinned by
    /// `TexDocumentBuilderSectionTests.experienceSynonymsTakeTheExperienceSpacingInTheEmittedTex`.
    @Test(arguments: ["Employment", "Work History"])
    func experienceSynonymsGainTheExperienceSpacing(title: String) {
        #expect(LaTeXResumeSection.classify(title) == .experience)
        #expect(LaTeXStyle.default.sectionVSpace(forSectionTitled: title) == "-1.5em")
    }

    /// Classification and its resulting order index, bucket by bucket. The indices are the ones the
    /// deleted `canonicalOrder(_:)` returned (verified equivalent against it before it was removed),
    /// written as literals so they keep pinning the canonical order now that it has one owner.
    @Test(arguments: [
        ("Education", LaTeXResumeSection.education, 0),
        ("Experience", .experience, 1),
        ("Employment History", .experience, 1),
        ("Projects", .projects, 2),
        ("Core Competencies", .skills, 3),
        ("Publications", .other, 4),
    ])
    func classificationMatchesTheCanonicalOrderIndices(title: String, section: LaTeXResumeSection, index: Int) {
        #expect(LaTeXResumeSection.classify(title) == section)
        #expect(LaTeXStyle.default.orderIndex(ofSectionTitled: title) == index)
    }

    // MARK: Order + visibility

    @Test func reorderingSectionsChangesTheirIndicesAndNothingElse() {
        var style = LaTeXStyle.default
        style.sectionOrder = [.experience, .skills, .education, .projects, .other]

        #expect(style.orderIndex(ofSectionTitled: "Experience") == 0)
        #expect(style.orderIndex(ofSectionTitled: "Skills") == 1)
        #expect(style.orderIndex(ofSectionTitled: "Education") == 2)
        #expect(style.isVisible(sectionTitled: "Education"))
        #expect(style.sectionVSpace(forSectionTitled: "Education") == "-1em")
    }

    /// A bucket left out of the order isn't dropped — it sorts last. Only `hiddenSections` hides.
    @Test func aSectionMissingFromTheOrderSortsLastRatherThanVanishing() {
        var style = LaTeXStyle.default
        style.sectionOrder = [.experience, .education]

        #expect(style.orderIndex(ofSectionTitled: "Publications") == 2)
        #expect(style.orderIndex(ofSectionTitled: "Skills") == 2)
        #expect(style.isVisible(sectionTitled: "Publications"))
    }

    @Test func hidingASectionAffectsOnlyThatBucket() {
        var style = LaTeXStyle.default
        style.hiddenSections = [.projects]

        #expect(!style.isVisible(sectionTitled: "Selected Projects"))
        #expect(style.isVisible(sectionTitled: "Experience"))
        #expect(style.isVisible(sectionTitled: "Publications"))
    }

    /// A spacing map missing an entry falls back to the canonical value, never to zero.
    @Test func missingSpacingFallsBackToTheCanonicalValue() {
        var style = LaTeXStyle.default
        style.sectionSpacingEm = [.experience: -2]

        #expect(style.sectionVSpace(forSectionTitled: "Experience") == "-2em")
        #expect(style.sectionVSpace(forSectionTitled: "Education") == "-1em")
    }

    // MARK: Ordering (the partition that drives section order)

    /// Sections are grouped by bucket in the style's order, each group keeping document order.
    @Test func orderedSectionsGroupsByBucketAndKeepsDocumentOrderWithinOne() {
        var style = LaTeXStyle.default
        style.sectionOrder = [.experience, .education]
        let titles = ["Education", "Experience", "Employment", "Projects", "Awards"]

        #expect(style.orderedSections(titles, titledBy: { $0 })
            == ["Experience", "Employment", "Education", "Projects", "Awards"])
    }

    /// The reason this is a partition and not a `sorted(by:)` with an index tiebreak: the tiebreak's
    /// absence is undetectable (the current stdlib sort happens to be stable), so document order has
    /// to be structural. Two same-bucket sections must never swap.
    @Test func orderedSectionsNeverReordersWithinABucket() {
        let titles = ["Experience", "Employment", "Work History"]
        #expect(LaTeXStyle.default.orderedSections(titles, titledBy: { $0 }) == titles)
    }

    /// An empty order isn't undefined — it degrades to plain document order, nothing dropped.
    @Test func anEmptySectionOrderKeepsDocumentOrder() {
        var style = LaTeXStyle.default
        style.sectionOrder = []
        let titles = ["Awards", "Core Skills", "Experience", "Education"]

        #expect(style.orderedSections(titles, titledBy: { $0 }) == titles)
    }

    /// A bucket repeated in the order can't duplicate its sections — a decoded style (Milestone D)
    /// or a drag-reorder bug could produce one.
    @Test func aDuplicatedBucketInTheOrderCannotDuplicateSections() {
        var style = LaTeXStyle.default
        style.sectionOrder = [.skills, .experience, .skills, .skills]
        let titles = ["Experience", "Core Skills", "Education"]

        let ordered = style.orderedSections(titles, titledBy: { $0 })
        #expect(ordered == ["Core Skills", "Experience", "Education"])
        #expect(ordered.count == titles.count)
    }

    @Test func orderedSectionsHandlesAnEmptyInput() {
        #expect(LaTeXStyle.default.orderedSections([String](), titledBy: { $0 }).isEmpty)
    }

    // MARK: Accent colour

    @Test func namedAccentsResolveToThePaletteTheClassesDefine() {
        #expect(LaTeXAccent.named(.red).hex == "DC3522")
        #expect(LaTeXAwesomeColor.red.latexName == "awesome-red")
        #expect(LaTeXAwesomeColor.templateDefault == .cyan)
        #expect(LaTeXAwesomeColor.allCases.count == 9)
    }

    @Test(arguments: [
        ("#dc3522", "DC3522"),
        (" 00a388 ", "00A388"),
        ("FFFFFF", "FFFFFF"),
    ])
    func customAccentHexIsNormalized(raw: String, expected: String) {
        #expect(LaTeXAccent.custom(hex: raw).hex == expected)
    }

    /// A malformed hex degrades to "no override" rather than emitting broken LaTeX.
    @Test(arguments: ["", "12345", "1234567", "GGGGGG", "#zzzzzz"])
    func malformedAccentHexResolvesToNoOverride(raw: String) {
        #expect(LaTeXAccent.custom(hex: raw).hex == nil)
    }

    // MARK: Number formatting

    /// A non-finite spacing value must not reach the document: `\\vspace{nanem}` fails the compile
    /// with "Missing number, treated as zero", i.e. a broken export from a value a numeric field
    /// can produce. It degrades to `0` instead.
    @Test func nonFiniteMeasurementsDegradeToZeroRatherThanBreakingTheCompile() {
        var style = LaTeXStyle.default
        style.sectionSpacingEm = [.experience: .nan, .skills: .infinity, .education: -.infinity]

        #expect(style.sectionVSpace(forSectionTitled: "Experience") == "0em")
        #expect(style.sectionVSpace(forSectionTitled: "Core Skills") == "0em")
        #expect(style.sectionVSpace(forSectionTitled: "Education") == "0em")
        #expect(LaTeXStyle.number(.nan) == "0")
        #expect(LaTeXStyle.fixed(.nan) == "0.00")

        // Magnitude is deliberately *not* clamped — bounding user input is Milestone E's job, and
        // silently rewriting a large number would hide what the user typed.
        #expect(LaTeXStyle.number(-12.5) == "-12.5")
    }

    @Test func measurementsFormatTheWayTheHandAuthoredTexWritesThem() {
        #expect(LaTeXStyle.number(-1) == "-1")
        #expect(LaTeXStyle.number(-1.5) == "-1.5")
        #expect(LaTeXStyle.number(1.08) == "1.08")
        #expect(LaTeXStyle.number(0) == "0")
        #expect(LaTeXStyle.fixed(0.5) == "0.50")
        #expect(LaTeXStyle.fixed(0.75) == "0.75")
    }

    // MARK: Codable (the styles library, Milestone D)

    @Test func styleRoundTripsThroughCodable() throws {
        var style = LaTeXStyle.default
        style.template = .awesomeCVCompact
        style.fontFamily = .sourceSansPro
        style.fontSizes = LaTeXFontSizes(resumePt: 7, coverLetterPt: 12)
        style.accent = .custom(hex: "123ABC")
        style.pageSize = .usLetter
        style.margins = LaTeXMargins(leftCm: 1, topCm: 1, rightCm: 1, bottomCm: 1, footskipCm: 0.3)
        style.sectionOrder = [.skills, .experience]
        style.hiddenSections = [.projects]
        style.sectionSpacingEm = [.skills: -0.25]
        style.customPreamble = "\\documentclass[10pt]{Class/Resume}"

        let data = try JSONEncoder().encode(style)
        #expect(try JSONDecoder().decode(LaTeXStyle.self, from: data) == style)
    }

    @Test func namedAndDefaultAccentsRoundTripToo() throws {
        for accent: LaTeXAccent in [.templateDefault, .named(.emerald), .custom(hex: "FF6138")] {
            var style = LaTeXStyle.default
            style.accent = accent
            let data = try JSONEncoder().encode(style)
            #expect(try JSONDecoder().decode(LaTeXStyle.self, from: data).accent == accent)
        }
    }
}
