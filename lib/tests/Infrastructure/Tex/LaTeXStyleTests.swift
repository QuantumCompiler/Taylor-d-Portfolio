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

    /// The section `\vspace` values the default style produces are exactly `sectionVSpace(_:)`'s.
    @Test(arguments: [
        ("Education", "-1em"),
        ("Professional Experience", "-1.5em"),
        ("Selected Projects", "-1.5em"),
        ("Technical Skills", "-0.5em"),
        ("Qualifications", "-0.5em"),
        ("Volunteering", "-1em"),
    ])
    func defaultSectionSpacingMatchesTheBuilder(title: String, expected: String) {
        #expect(LaTeXStyle.default.sectionVSpace(forSectionTitled: title) == expected)
        #expect(TexDocumentBuilder.sectionVSpace(title) == expected)
    }

    /// **The one deliberate divergence from today's output.** The builder's two classifiers
    /// disagree with each other: `canonicalOrder(_:)` treats "Employment" / "Work History" as
    /// *experience* (sorting them second), but `sectionVSpace(_:)` doesn't list those synonyms, so
    /// they fall through to the generic `-1em` — an experience section that sorts as experience yet
    /// is spaced as "other". A style has **one** bucket per section, so this can't be reproduced;
    /// the bucket wins and those titles pick up the experience spacing. Recorded here so Milestone
    /// C's byte-for-byte claim stays honest: default output is identical **except** for a résumé
    /// whose experience section is titled "Employment" or "Work History".
    @Test(arguments: ["Employment", "Work History"])
    func experienceSynonymsGainTheExperienceSpacing(title: String) {
        #expect(LaTeXResumeSection.classify(title) == .experience)
        #expect(LaTeXStyle.default.sectionVSpace(forSectionTitled: title) == "-1.5em")
        // What the builder does today — the inconsistency this unifies.
        #expect(TexDocumentBuilder.sectionVSpace(title) == "-1em")
        #expect(TexDocumentBuilder.canonicalOrder(title) == 1)
    }

    /// Section classification matches the builder's ordering heuristic, bucket for bucket — the
    /// two must not drift, since Milestone C replaces one with the other.
    @Test(arguments: [
        ("Education", LaTeXResumeSection.education),
        ("Experience", .experience),
        ("Employment History", .experience),
        ("Projects", .projects),
        ("Core Competencies", .skills),
        ("Publications", .other),
    ])
    func classificationMatchesTheBuildersCanonicalOrder(title: String, section: LaTeXResumeSection) {
        #expect(LaTeXResumeSection.classify(title) == section)
        #expect(LaTeXStyle.default.orderIndex(ofSectionTitled: title)
            == TexDocumentBuilder.canonicalOrder(title))
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
