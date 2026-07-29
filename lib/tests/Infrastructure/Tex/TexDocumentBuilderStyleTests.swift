//
//  TexDocumentBuilderStyleTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Tex — style-driven preambles (v0.7.0 Milestone B).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("TexDocumentBuilder · style")
struct TexDocumentBuilderStyleTests {

    private let resumeMarkdown = """
    # Taylor J. Larrechea
    **iOS Engineer — SwiftUI · MVVM · Applied AI**

    ## Summary
    Mid-level iOS engineer shipping production SwiftUI features & 100% ownership.

    ## Core Skills
    iOS Engineering: SwiftUI, MVVM, async/await

    ## Experience
    ### iOS Engineer — NRG Energy
    Lehi, UT · Jun. 2025 – Present
    - Design & implement production SwiftUI features.
    """

    private let coverMarkdown = """
    ## About Me
    My name is Taylor, a full-stack engineer with 100% commitment & drive.
    """

    // MARK: The golden regression — the default style reproduces the pre-v0.7.0 output

    /// The **whole document**, captured from the builder *before* Milestone B parameterized it —
    /// not just the preamble, so a stray change anywhere in the emitted `.tex` trips this. If a
    /// change to the style system alters the default look, this fails; that's the point of
    /// `LaTeXStyle.default` existing at all.
    ///
    /// It stays exact through Milestone C with **one** documented exemption, which this fixture
    /// deliberately doesn't exercise: a résumé whose experience section is titled "Employment" or
    /// "Work History" now takes the experience `-1.5em` rather than the old generic `-1em` (the two
    /// pre-v0.7.0 classifiers disagreed about those titles). See
    /// `TexDocumentBuilderSectionTests.experienceSynonymsTakeTheExperienceSpacingInTheEmittedTex`.
    ///
    /// **Second sanctioned exemption (v0.7.0 Milestone E).** The skills grid's `\arraystretch` is
    /// now wrapped in a `{…}` group, so these two lines gained a brace. That is a deliberate,
    /// measured change to the default output: ungrouped, the 0.7 stretch leaked into every
    /// `tabular*` after the grid, compressing the following entry's rows by ~3.9pt. Everything
    /// else here is still the pre-v0.7.0 capture.
    private let goldenResume = #"""
    \documentclass[6pt]{Class/Resume}
    \geometry{left=0.50cm, top=0.50cm, right=0.50cm, bottom=0.75cm, footskip=0.25cm}
    \nonstopmode
    \fontdir[fonts/]
    \pageHeader
    \position{iOS Engineer — SwiftUI · MVVM · Applied AI}
    \pageFooter{Résumé}

    % Generated helpers (Taylor'd Portfolio): dash-free entry rows with awesome-cv spacing.
    \newcommand{\cventrysolo}[4]{%
      \vspace{-2.0mm}\setlength\tabcolsep{0pt}\setlength{\extrarowheight}{0pt}%
      \begin{tabular*}{\textwidth}{@{\extracolsep{\fill}} L{\dimexpr\textwidth-6.0cm} r}%
        \entrytitlestyle{#1} & {\entrylocationstyle{#2}\entrydatestyle{ - #3}} \\%
        \multicolumn{2}{L{\textwidth}}{\vspace{0mm}\descriptionstyle{#4}}%
      \end{tabular*}%
    }
    \newcommand{\cvprojectsolo}[2]{%
      \vspace{-2.0mm}\setlength\tabcolsep{0pt}\setlength{\extrarowheight}{0pt}%
      \begin{tabular*}{\textwidth}{@{\extracolsep{\fill}} L{\textwidth}}%
        \entrytitlestyle{#1} \\%
        \multicolumn{1}{L{\textwidth}}{\descriptionstyle{#2}}%
      \end{tabular*}%
    }
    \begin{document}

    \makecvheader

    \vspace{-0.5em}
    \begin{justify}{\paragraphstyle Mid-level iOS engineer shipping production SwiftUI features \& 100\% ownership.}\end{justify}

    \vspace{-1.5em}
    \cvsection{Experience}

    \begin{cventries}

        \cventry
        {iOS Engineer}
        {NRG Energy}
        {Lehi, UT}
        {Jun. 2025 – Present}
        {
        \begin{cvitems}
            \item {Design \& implement production SwiftUI features.}
        \end{cvitems}
        }

    \end{cventries}

    \vspace{-0.5em}
    \cvsection{Core Skills}

    {\renewcommand{\arraystretch}{0.7}
    \begin{cvskills}
        \cvskill
        {iOS Engineering}
        {SwiftUI, MVVM, async/await}
    \end{cvskills}}

    \end{document}

    """#

    private let goldenCoverLetter = #"""
    \documentclass[11pt, a4paper]{Class/CoverLetter}
    \geometry{left=0.50cm, top=0.50cm, right=0.50cm, bottom=0.75cm, footskip=0.25cm}
    \nonstopmode
    \fontdir[fonts/]
    \pageHeader
    \pageFooter{Cover Letter}

    \begin{document}

    \makecvheader

    \setlength{\parskip}{1.0em}
    \linespread{1.08}\selectfont

    \begin{cvletter}

    \lettersection{About Me}

    My name is Taylor, a full-stack engineer with 100\% commitment \& drive.

    \end{cvletter}

    \makeletterclosing

    \end{document}

    """#

    @Test func defaultStyleReproducesThePreviousResumeExactly() {
        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown) == goldenResume)
        // …and the explicit default is the same call.
        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: .default) == goldenResume)
    }

    @Test func defaultStyleReproducesThePreviousCoverLetterExactly() {
        #expect(TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown) == goldenCoverLetter)
        #expect(TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: .default) == goldenCoverLetter)
    }

    /// The default emits **no** font-family, colour, or résumé paper option — the three
    /// `.templateDefault` cases exist so "unchanged" stays representable.
    @Test func defaultStyleEmitsNoOverrides() {
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown)
        #expect(!tex.contains("\\newfontfamily"))
        #expect(!tex.contains("\\colorlet{awesome}"))
        #expect(!tex.contains("\\definecolor{awesome}"))
        #expect(!tex.contains("letterpaper"))
    }

    // MARK: The body never depends on the style

    /// A style themes the preamble; the document body is app-generated and escaped, identically
    /// under every **non-section** style field. Since Milestone C, `sectionOrder` / `hiddenSections`
    /// / `sectionSpacingEm` *do* reach the body — and they're the only fields that may, which is
    /// what this narrowed invariant pins (its converse is
    /// `TexDocumentBuilderSectionTests.sectionFieldsNeverAffectThePreamble`).
    @Test func bodyIsIdenticalAcrossStyles() {
        var style = LaTeXStyle.default
        style.fontFamily = .roboto
        style.accent = .named(.red)
        style.pageSize = .usLetter
        style.fontSizes = LaTeXFontSizes(resumePt: 8, coverLetterPt: 12)
        style.margins = LaTeXMargins(leftCm: 1.25, topCm: 1, rightCm: 1.25, bottomCm: 1, footskipCm: 0.5)

        func body(_ tex: String) -> String {
            guard let range = tex.range(of: "\\begin{document}") else { return tex }
            return String(tex[range.lowerBound...])
        }

        #expect(body(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style))
            == body(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown)))
        #expect(body(TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: style))
            .contains("100\\% commitment \\& drive"))
    }

    // MARK: Typography / geometry / colour / page size

    @Test func fontSizesDriveTheDocumentClassOptions() {
        var style = LaTeXStyle.default
        style.fontSizes = LaTeXFontSizes(resumePt: 7.5, coverLetterPt: 12)

        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)
            .hasPrefix("\\documentclass[7.5pt]{Class/Resume}"))
        #expect(TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: style)
            .hasPrefix("\\documentclass[12pt, a4paper]{Class/CoverLetter}"))
    }

    /// A chosen page size applies to **both** documents — the unification of today's divergent
    /// résumé (no paper option) and letter (`a4paper`) geometry.
    @Test func aChosenPageSizeAppliesToBothDocuments() {
        var style = LaTeXStyle.default
        style.pageSize = .usLetter

        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)
            .hasPrefix("\\documentclass[6pt, letterpaper]{Class/Resume}"))
        #expect(TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: style)
            .hasPrefix("\\documentclass[11pt, letterpaper]{Class/CoverLetter}"))

        style.pageSize = .a4
        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)
            .hasPrefix("\\documentclass[6pt, a4paper]{Class/Resume}"))
    }

    @Test func marginsDriveTheGeometryLineOnBothDocuments() {
        var style = LaTeXStyle.default
        style.margins = LaTeXMargins(leftCm: 1.25, topCm: 1, rightCm: 1.25, bottomCm: 2, footskipCm: 0.5)
        let expected = "\\geometry{left=1.25cm, top=1.00cm, right=1.25cm, bottom=2.00cm, footskip=0.50cm}"

        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style).contains(expected))
        #expect(TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: style).contains(expected))
    }

    @Test func aNamedAccentIsEmittedByNameAndACustomOneAsHex() {
        var style = LaTeXStyle.default
        style.accent = .named(.red)
        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)
            .contains("\\colorlet{awesome}{awesome-red}"))

        style.accent = .custom(hex: "#123abc")
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)
        #expect(tex.contains("\\definecolor{awesome}{HTML}{123ABC}"))
        #expect(!tex.contains("\\colorlet{awesome}"))
    }

    /// A malformed custom hex degrades to no override rather than emitting broken LaTeX that would
    /// fail the compile.
    @Test func aMalformedAccentEmitsNothing() {
        var style = LaTeXStyle.default
        style.accent = .custom(hex: "nope")
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)
        #expect(!tex.contains("definecolor{awesome}"))
        #expect(!tex.contains("\\colorlet{awesome}"))
    }

    @Test func aChosenFontFamilyRepointsTheClassBodyFonts() {
        var style = LaTeXStyle.default
        style.fontFamily = .roboto
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)

        #expect(tex.contains("\\newfontfamily\\styleBodyFont["))
        #expect(tex.contains("Path=fonts/"))
        #expect(tex.contains("Extension=.ttf"))
        #expect(tex.contains("]{Roboto}"))
        #expect(tex.contains("\\renewcommand*{\\bodyfont}{\\styleBodyFont}"))
        #expect(tex.contains("\\renewcommand*{\\bodyfontlight}{\\styleBodyFontLight}"))

        style.fontFamily = .sourceSansPro
        let sourceSans = TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: style)
        #expect(sourceSans.contains("Extension=.otf"))
        #expect(sourceSans.contains("ItalicFont=*-It,"))     // Source Sans' suffix, not Roboto's
        #expect(sourceSans.contains("]{SourceSansPro}"))
    }

    /// The letter's body spacing comes from the style too.
    @Test func letterBodySpacingComesFromTheStyle() {
        var style = LaTeXStyle.default
        style.letterParagraphSkipEm = 0.8
        style.letterLineSpread = 1.0

        let tex = TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: style)
        #expect(tex.contains("\\setlength{\\parskip}{0.8em}"))
        #expect(tex.contains("\\linespread{1}\\selectfont"))
    }

    /// A style's template chooses the classes — the compact built-in reuses the same ones but
    /// brings its own geometry.
    @Test func theTemplateChoosesTheClassesAndItsDefaults() {
        let compact = LaTeXTemplateDescriptor.awesomeCVCompact.defaultStyle
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: compact)

        #expect(tex.hasPrefix("\\documentclass[6pt]{Class/Resume}"))
        #expect(tex.contains("\\geometry{left=0.35cm, top=0.35cm, right=0.35cm, bottom=0.55cm, footskip=0.20cm}"))
        // It deliberately keeps the **canonical** section spacing: its tighter values were inert
        // until Milestone C made spacing style-driven, and once live they ran the first section's
        // rule into the lead paragraph (measured under lualatex). Margins are its differentiator.
        #expect(tex.contains("\\vspace{-1.5em}\n\\cvsection{Experience}"))
        #expect(tex.contains("\\vspace{-0.5em}\n\\cvsection{Core Skills}"))
        #expect(LaTeXTemplateDescriptor.awesomeCVCompact.defaultStyle.sectionSpacingEm
            == LaTeXStyle.default.sectionSpacingEm)
    }

    // MARK: The raw-LaTeX preamble override (v0.7.0 Milestone F)

    private var override: String {
        """
        \\geometry{left=3.00cm, top=3.00cm, right=3.00cm, bottom=3.00cm, footskip=0.25cm}
        \\colorlet{awesome}{awesome-nephritis}
        \\renewcommand{\\pageHeader}{\\name{Alex}{Sample}\\email{alex@example.com}}
        """
    }

    private func overriding(_ preamble: String) -> LaTeXStyle {
        var style = LaTeXStyle.default
        style.fontFamily = .roboto              // ← would emit \newfontfamily…
        style.accent = .named(.red)             // ← …and \colorlet, both replaced by the override
        style.margins = LaTeXMargins(leftCm: 9, topCm: 9, rightCm: 9, bottomCm: 9, footskipCm: 9)
        style.customPreamble = preamble
        return style
    }

    /// The override replaces the **style block** verbatim: geometry, font family and accent are
    /// the user's now.
    @Test func anOverrideReplacesTheStyleBlockVerbatim() {
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: overriding(override))

        #expect(tex.contains(override))
        #expect(!tex.contains("left=9.00cm"))            // the style's own margins are gone
        #expect(!tex.contains("\\newfontfamily"))         // …and its font override
        #expect(!tex.contains("awesome-red"))            // …and its accent
    }

    /// …but the **frame** survives, including the entry helpers the generated body calls. Losing
    /// those would make the same style compile one résumé and hard-fail the next.
    @Test func theDocumentFrameSurvivesAnOverride() throws {
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: overriding(override))

        #expect(tex.hasPrefix("\\documentclass[6pt]{Class/Resume}"))
        for required in ["\\nonstopmode", "\\fontdir[fonts/]", "\\pageHeader", "\\position{",
                         "\\pageFooter{Résumé}", "\\newcommand{\\cventrysolo}",
                         "\\newcommand{\\cvprojectsolo}", "\\begin{document}"] {
            #expect(tex.contains(required), "the frame must keep \(required)")
        }
        // …and the override lands before the frame's own invocation, which is what lets it
        // `\renewcommand{\pageHeader}` — note the override *contains* that word, so this looks
        // for the frame's own line rather than the first textual match.
        let overrideAt = try #require(tex.range(of: override))
        let invocationAt = try #require(tex.range(of: "\n\\pageHeader\n"))
        #expect(overrideAt.upperBound <= invocationAt.lowerBound)
    }

    /// The contract's "body unchanged": an override themes, it doesn't touch what the app wrote.
    @Test func anOverrideLeavesTheBodyByteIdentical() {
        func body(_ tex: String) -> String {
            guard let range = tex.range(of: "\\begin{document}") else { return tex }
            return String(tex[range.lowerBound...])
        }
        #expect(body(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: overriding(override)))
            == body(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown)))
        #expect(body(TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: overriding(override)))
            == body(TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown)))
    }

    /// One override serves both documents **because** it can't contain `\documentclass` — the app
    /// writes that, and the two deliverables need different ones.
    @Test func oneOverrideServesBothDocumentsWithTheirOwnClasses() {
        let style = overriding(override)
        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)
            .hasPrefix("\\documentclass[6pt]{Class/Resume}"))
        #expect(TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: style)
            .hasPrefix("\\documentclass[11pt, a4paper]{Class/CoverLetter}"))
    }

    /// A blank override is treated as no override — an empty preamble compiles to
    /// "`\normalsize is not defined`", which tells a user nothing about what they did.
    @Test(arguments: ["", "   ", "\n\n  \n"])
    func aBlankOverrideFallsBackToTheGeneratedBlock(blank: String) {
        var style = LaTeXStyle.default
        style.customPreamble = blank
        #expect(style.effectiveCustomPreamble == nil)
        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)
            == TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown))
    }

    /// No override → byte-identical to Milestone B/C output (the goldens above already pin this;
    /// this states it as the override's own contract).
    @Test func noOverrideChangesNothing() {
        var style = LaTeXStyle.default
        style.customPreamble = nil
        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style) == goldenResume)
    }

    /// A preamble ending in a `%` comment must not swallow the frame's next line.
    @Test func anOverrideEndingInACommentStillTerminates() {
        var style = LaTeXStyle.default
        style.customPreamble = "\\geometry{left=1cm, top=1cm, right=1cm, bottom=1cm}   % mine"
        let tex = TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)

        #expect(tex.contains("% mine\n\\nonstopmode"))
    }

    /// The `.tex` **source** is unaffected by whether the override compiles — that's how a user
    /// debugs one, so it must never be gated on a test compile.
    @Test func theTexSourceCarriesEvenAnUncompilableOverride() {
        var style = LaTeXStyle.default
        style.customPreamble = "\\thisIsNotACommand{}"
        #expect(TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style)
            .contains("\\thisIsNotACommand{}"))
    }

    // MARK: Integration — a styled document still compiles

    /// A realistic override — the one a user actually needs, replacing the class's hardcoded
    /// name — compiles for real, and the generated body still typesets under it.
    @Test func aWorkingOverrideCompilesUnderLualatex() async throws {
        let client = LaTeXProcessClient()
        guard client.isAvailable, client.assets?.isComplete == true else { return }
        var style = LaTeXStyle.default
        style.customPreamble = """
        \\geometry{left=1.00cm, top=1.00cm, right=1.00cm, bottom=1.00cm, footskip=0.25cm}
        \\colorlet{awesome}{awesome-nephritis}
        \\renewcommand{\\pageHeader}{\\name{Alex}{Sample}\\email{alex@example.com}\\mobile{(555) 010-0000}}
        """
        let pdf = try await client.compile(
            tex: TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style),
            jobName: "overridden resume")
        #expect(pdf.prefix(4).elementsEqual(Data("%PDF".utf8)))
    }

    /// A broken override fails **gracefully**: a non-zero exit with a diagnosable log, not a hang
    /// waiting on a TeX prompt no one can answer.
    @Test func aBrokenOverrideFailsWithALogRatherThanHanging() async throws {
        let client = LaTeXProcessClient()
        guard client.isAvailable, client.assets?.isComplete == true else { return }
        var style = LaTeXStyle.default
        style.customPreamble = "\\thisIsNotAControlSequence{}"

        await #expect(throws: (any Error).self) {
            _ = try await client.compile(
                tex: TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style),
                jobName: "broken override")
        }
    }

    @Test func aFullyStyledDocumentCompilesUnderLualatex() async throws {
        let client = LaTeXProcessClient()
        guard client.isAvailable, client.assets?.isComplete == true else {
            return   // no TeX install / assets — don't fail the suite
        }
        var style = LaTeXStyle.default
        style.fontFamily = .roboto
        style.accent = .custom(hex: "DC3522")
        style.pageSize = .usLetter
        style.fontSizes = LaTeXFontSizes(resumePt: 7, coverLetterPt: 12)
        style.margins = LaTeXMargins(leftCm: 1, topCm: 1, rightCm: 1, bottomCm: 1.25, footskipCm: 0.3)

        let resumePDF = try await client.compile(
            tex: TexDocumentBuilder.resume(fromMarkdown: resumeMarkdown, style: style), jobName: "styled resume")
        #expect(resumePDF.prefix(4).elementsEqual(Data("%PDF".utf8)))

        var letterStyle = style
        letterStyle.fontFamily = .sourceSansPro
        letterStyle.accent = .named(.nephritis)
        let coverPDF = try await client.compile(
            tex: TexDocumentBuilder.coverLetter(fromMarkdown: coverMarkdown, style: letterStyle),
            jobName: "styled cover letter")
        #expect(coverPDF.prefix(4).elementsEqual(Data("%PDF".utf8)))
    }
}
