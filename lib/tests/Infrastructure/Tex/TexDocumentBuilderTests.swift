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

    @Test func resumeEmitsDriverSectionsEntriesAndSkills() {
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown)
        #expect(tex.contains("\\documentclass[6pt]{Class/Resume}"))
        #expect(tex.contains("\\makecvheader"))
        #expect(tex.contains("\\position{iOS Engineer — SwiftUI · MVVM · Applied AI}"))   // bold headline
        #expect(tex.contains("\\cvsection{Experience}"))
        #expect(tex.contains("\\begin{cvskills}"))
        #expect(tex.contains("\\cvskill{iOS Engineering}{SwiftUI, MVVM, async/await}"))
        #expect(tex.contains("\\begin{cvitems}"))
        #expect(tex.contains("\\item {Design \\& implement"))   // bullet + escaped ampersand
        #expect(tex.contains("\\entrytitlestyle{iOS Engineer — NRG Energy / Vivint}"))
        #expect(tex.contains("\\entrydatestyle{Lehi, UT · Jun. 2025 – Present}"))
        #expect(tex.hasSuffix("\\end{document}\n"))
        // The redundant contact line (class header owns it) isn't rendered.
        #expect(!tex.contains("tj@example.com"))
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
