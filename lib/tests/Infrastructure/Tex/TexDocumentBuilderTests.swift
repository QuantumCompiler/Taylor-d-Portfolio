//
//  TexDocumentBuilderTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Tex — Markdown → awesome-cv .tex (Milestone C, C-parse).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("TexDocumentBuilder")
struct TexDocumentBuilderTests {

    private let resumeMarkdown = """
    # Taylor J. Larrechea
    **iOS Engineer — SwiftUI · MVVM · Applied AI**
    Mobile: (970) 366-2551 | Email: tj@example.com | GitHub: QuantumCompiler

    ## Summary
    Mid-level iOS engineer shipping production SwiftUI features & 100% ownership.

    ## Core Skills
    iOS Engineering: SwiftUI, MVVM, async/await
    Applied AI: RAG, MCP, fine-tuning (LoRA)

    ## Experience
    ### iOS Engineer — NRG Energy / Vivint
    Lehi, UT · Jun. 2025 – Present
    - Design & implement production SwiftUI features (100% reliability).
    - Integrate Platform APIs and R&D tooling.

    ### Customer Engineer — Applied Materials
    Lehi, UT · Oct. 2022 – May 2025
    - Supported defect metrology for Intel R&D.
    """

    private let coverMarkdown = """
    ## About Me
    My name is Taylor, a full-stack engineer with 100% commitment & drive.

    ## Why Acme
    Your work on API gateways matches my **Ommi** project.

    ## Why Me
    I ship fast & care about craft.
    """

    // MARK: LaTeX escaping + inline

    @Test func escapesLaTeXSpecialCharacters() {
        #expect(TexDocumentBuilder.escape("a & b % c $ d # e _ f") == "a \\& b \\% c \\$ d \\# e \\_ f")
        #expect(TexDocumentBuilder.escape("{x}") == "\\{x\\}")
        #expect(TexDocumentBuilder.escape("a~b^c\\d") == "a\\textasciitilde{}b\\textasciicircum{}c\\textbackslash{}d")
    }

    @Test func inlineRendersBoldAndItalicAndEscapes() {
        let out = TexDocumentBuilder.inlineLaTeX("**bold** and *it* & plain")
        #expect(out.contains("\\textbf{bold}"))
        #expect(out.contains("\\textit{it}"))
        #expect(out.contains("\\& plain"))          // ampersand escaped
        // Titles strip emphasis (a class style already bolds them).
        #expect(TexDocumentBuilder.plainLaTeX("**iOS Engineer — Co**") == "iOS Engineer — Co")
    }

    // MARK: Heuristics

    @Test func detectsBoldLeadsAndContactLines() {
        #expect(TexDocumentBuilder.isBold("**all bold**"))
        #expect(TexDocumentBuilder.isBold("**a** plain") == false)
        #expect(TexDocumentBuilder.isBold("plain") == false)
        #expect(TexDocumentBuilder.isContactLine("Mobile: 1 | Email: a@b.com | GitHub: x"))
        #expect(TexDocumentBuilder.isContactLine("name@example.com"))
        #expect(TexDocumentBuilder.isContactLine("Experience") == false)
    }

    @Test func splitsSectionsAtHeadingLevel() {
        let blocks = MarkdownBlockParser.blocks(from: "intro\n\n## A\nx\n\n## B\ny")
        let (preamble, sections) = TexDocumentBuilder.split(blocks, atHeadingLevel: 2)
        #expect(preamble.contains(.paragraph(text: "intro")))
        #expect(sections.map(\.title) == ["A", "B"])
    }

    // MARK: Résumé structure

    @Test func resumeEmitsDriverEntriesAndSkillsInAwesomeCVMacros() {
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown)
        #expect(tex.contains("\\documentclass[6pt]{Class/Resume}"))
        #expect(tex.contains("\\makecvheader"))
        #expect(tex.contains("\\position{iOS Engineer — SwiftUI · MVVM · Applied AI}"))   // bold headline
        #expect(tex.contains("\\cvsection{Experience}"))
        // Entries use \begin{cventries} + \cventry, split into position/org and location/date.
        #expect(tex.contains("\\begin{cventries}"))
        #expect(tex.contains("\\cventry"))
        #expect(tex.contains("{iOS Engineer}"))
        #expect(tex.contains("{NRG Energy / Vivint}"))
        #expect(tex.contains("{Lehi, UT}"))
        #expect(tex.contains("{Jun. 2025 – Present}"))          // date kept whole (split on middot, not dash)
        #expect(tex.contains("\\begin{cvitems}"))
        #expect(tex.contains("\\item {Design \\& implement"))   // bullet + escaped ampersand
        // Skills grid uses the résumé's \arraystretch + \cvskill.
        #expect(tex.contains("\\renewcommand{\\arraystretch}{0.7}"))
        #expect(tex.contains("\\begin{cvskills}"))
        #expect(tex.contains("{iOS Engineering}"))
        #expect(tex.contains("{SwiftUI, MVVM, async/await}"))
        #expect(tex.hasSuffix("\\end{document}\n"))
        #expect(!tex.contains("tj@example.com"))                // redundant contact line dropped
        #expect(!tex.contains("\\entrytitlestyle{iOS Engineer — NRG"))   // no longer the bare-style approach
    }

    @Test func resumeReordersSectionsSpacesThemAndLeadsWithSummary() {
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown)
        // Canonical order: Experience (1) before Core Skills (3), though the Markdown had Skills first.
        let experience = tex.range(of: "\\cvsection{Experience}")
        let skills = tex.range(of: "\\cvsection{Core Skills}")
        #expect(experience != nil && skills != nil && experience!.lowerBound < skills!.lowerBound)
        // Per-section \vspace tweaks, matching the hand-authored section files.
        #expect(tex.contains("\\vspace{-1.5em}\n\\cvsection{Experience}"))
        #expect(tex.contains("\\vspace{-0.5em}\n\\cvsection{Core Skills}"))
        // Summary renders as a lead paragraph, not a titled section.
        #expect(!tex.contains("\\cvsection{Summary}"))
        #expect(tex.contains("\\paragraphstyle Mid-level iOS engineer"))
        // The dash-free entry helpers are injected.
        #expect(tex.contains("\\newcommand{\\cvprojectsolo}"))
    }

    @Test func entryFieldSplittingSeparatesTitleAndLocationDate() {
        #expect(TexDocumentBuilder.splitOnSeparator("iOS Engineer — NRG Energy")! == ("iOS Engineer", "NRG Energy"))
        #expect(TexDocumentBuilder.splitOnSeparator("no separator here") == nil)
        // Location/date splits on the middot — NOT the date range's dash.
        let split = TexDocumentBuilder.splitLocationDate("Lehi, UT · Jun. 2025 – Present")
        #expect(split.location == "Lehi, UT")
        #expect(split.date == "Jun. 2025 – Present")
        #expect(TexDocumentBuilder.looksDated("Jun. 2025 – Present"))
        #expect(TexDocumentBuilder.looksDated("Creator & Lead Developer") == false)
    }

    @Test func canonicalOrderAndSpacingMatchTheManual() {
        #expect(TexDocumentBuilder.canonicalOrder("Education") == 0)
        #expect(TexDocumentBuilder.canonicalOrder("Work Experience") == 1)
        #expect(TexDocumentBuilder.canonicalOrder("Projects") == 2)
        #expect(TexDocumentBuilder.canonicalOrder("Core Skills") == 3)
        #expect(TexDocumentBuilder.canonicalOrder("Awards") == 4)
        #expect(TexDocumentBuilder.sectionVSpace("Education") == "-1em")
        #expect(TexDocumentBuilder.sectionVSpace("Experience") == "-1.5em")
        #expect(TexDocumentBuilder.sectionVSpace("Qualifications") == "-0.5em")
    }

    @Test func projectsWithoutDatesUseCvproject() {
        // A projects section (no dated subtitles) → \cvproject / \cvprojectsolo, not \cventry.
        let md = "## Projects\n### Formulator Pro\n- Cross-platform Electron app.\n\n### Ommi\nCreator & Lead Developer\n- Go AI platform."
        let tex = TexDocumentBuilder.resume(fromMarkdown: md)
        #expect(tex.contains("\\cvprojectsolo\n    {Formulator Pro}"))     // no role → solo
        #expect(tex.contains("\\cvproject\n    {Creator \\& Lead Developer}\n    {Ommi}"))  // role subtitle (& escaped)
    }

    @Test func coverLetterEmitsLetterSections() {
        let tex = TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown)
        #expect(tex.contains("\\documentclass[11pt, a4paper]{Class/CoverLetter}"))
        #expect(tex.contains("\\begin{cvletter}"))
        #expect(tex.contains("\\lettersection{About Me}"))
        #expect(tex.contains("\\lettersection{Why Acme}"))
        #expect(tex.contains("\\textbf{Ommi}"))                 // inline bold survives in the body
        #expect(tex.contains("100\\% commitment \\& drive"))    // escaped % and &
        #expect(tex.contains("\\makeletterclosing"))
    }

    // MARK: Integration — the emitted .tex actually compiles (skipped without lualatex)

    @Test func emittedTexCompilesUnderLualatex() async throws {
        let client = LaTeXProcessClient()
        guard client.isAvailable, client.assets?.isComplete == true else {
            return   // no TeX install / assets — don't fail the suite
        }
        let resumePDF = try await client.compile(
            tex: TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown), jobName: "resume")
        #expect(resumePDF.prefix(4).elementsEqual(Data("%PDF".utf8)))

        let coverPDF = try await client.compile(
            tex: TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown), jobName: "cover letter")
        #expect(coverPDF.prefix(4).elementsEqual(Data("%PDF".utf8)))
    }
}
