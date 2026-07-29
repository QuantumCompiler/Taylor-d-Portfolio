//
//  TexDocumentBuilderSectionTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Tex — style-driven section order, visibility & spacing (v0.7.0 Milestone C).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("TexDocumentBuilder · sections")
struct TexDocumentBuilderSectionTests {

    /// All four canonical buckets plus an unknown one ("Awards"), in deliberately **scrambled**
    /// Markdown order, plus a Summary — so ordering, visibility and spacing are each observable.
    private let fixture = """
    # Taylor J. Larrechea
    **iOS Engineer — SwiftUI · MVVM · Applied AI**

    ## Summary
    Mid-level iOS engineer shipping production SwiftUI features.

    ## Awards
    ### Employee of the Year
    NRG Energy · 2025
    - Recognised for the SwiftUI rewrite.

    ## Core Skills
    iOS Engineering: SwiftUI, MVVM, async/await

    ## Experience
    ### iOS Engineer — NRG Energy
    Lehi, UT · Jun. 2025 – Present
    - Design & implement production SwiftUI features.

    ## Projects
    ### Formulator Pro
    - Cross-platform Electron app.

    ## Education
    ### B.S. Physics — University of Utah
    Salt Lake City, UT · 2019
    - Graduated with honours.
    """

    /// The same document with the `## Projects` block physically removed — the reference for
    /// "hiding a section is indistinguishable from it never having been there".
    private let fixtureWithoutProjects = """
    # Taylor J. Larrechea
    **iOS Engineer — SwiftUI · MVVM · Applied AI**

    ## Summary
    Mid-level iOS engineer shipping production SwiftUI features.

    ## Awards
    ### Employee of the Year
    NRG Energy · 2025
    - Recognised for the SwiftUI rewrite.

    ## Core Skills
    iOS Engineering: SwiftUI, MVVM, async/await

    ## Experience
    ### iOS Engineer — NRG Energy
    Lehi, UT · Jun. 2025 – Present
    - Design & implement production SwiftUI features.

    ## Education
    ### B.S. Physics — University of Utah
    Salt Lake City, UT · 2019
    - Graduated with honours.
    """

    /// The `\cvsection{…}` titles in the order the builder emitted them — a sequence assertion,
    /// which catches an ordering bug a pair of `contains` checks would miss.
    private func emittedSections(_ tex: String) -> [String] {
        tex.components(separatedBy: "\\cvsection{").dropFirst().compactMap { chunk in
            chunk.firstIndex(of: "}").map { String(chunk[chunk.startIndex..<$0]) }
        }
    }

    private func offset(of needle: String, in tex: String) -> Int? {
        tex.range(of: needle).map { tex.distance(from: tex.startIndex, to: $0.lowerBound) }
    }

    // MARK: Ordering

    @Test func defaultStyleEmitsTheCanonicalSectionOrder() {
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture)
        #expect(emittedSections(tex) == ["Education", "Experience", "Projects", "Core Skills", "Awards"])
    }

    @Test func aReorderedStyleReordersTheEmittedSections() {
        var style = LaTeXStyle.default
        style.sectionOrder = [.skills, .projects, .experience, .education, .other]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        #expect(emittedSections(tex) == ["Core Skills", "Projects", "Experience", "Education", "Awards"])
        // The content travels with its header — not just the titles moving.
        let skills = offset(of: "\\cvsection{Core Skills}", in: tex)
        let skillContent = offset(of: "{iOS Engineering}", in: tex)
        let projects = offset(of: "\\cvsection{Projects}", in: tex)
        #expect(skills != nil && skillContent != nil && projects != nil)
        #expect(skills! < skillContent! && skillContent! < projects!)
    }

    /// Two sections in the **same** bucket keep their Markdown order. Ordering is a partition over
    /// `sectionOrder` (`LaTeXStyle.orderedSections`), not a `sorted(by:)` — so this is structural
    /// rather than resting on sort stability, and `LaTeXStyleTests` can pin it at unit level too.
    @Test func sectionsInTheSameBucketKeepTheirMarkdownOrder() {
        let markdown = """
        # Taylor J. Larrechea

        ## Experience
        ### iOS Engineer
        Lehi, UT · 2025 – Present
        - Shipped things.

        ## Employment
        ### Field Engineer
        Lehi, UT · 2022 – 2025
        - Supported things.
        """
        #expect(emittedSections(TexDocumentBuilder.resume(fromMarkdown: markdown)) == ["Experience", "Employment"])
    }

    /// Buckets the style's order omits sort **last**, in Markdown order — omission means "send to
    /// the end", never "drop". Nothing disappears just because the user didn't mention it.
    @Test func bucketsMissingFromTheOrderSortLastInMarkdownOrder() {
        var style = LaTeXStyle.default
        style.sectionOrder = [.skills, .education]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        #expect(emittedSections(tex) == ["Core Skills", "Education", "Awards", "Experience", "Projects"])
    }

    /// An unrecognised section title lands in `.other` and is never dropped.
    @Test func anUnknownSectionIsNeverDroppedAndSortsLast() {
        let markdown = fixture + """


        ## Volunteering
        ### Trail crew
        Utah · 2024
        - Built trail.
        """
        let sections = emittedSections(TexDocumentBuilder.resume(fromMarkdown: markdown))
        #expect(sections == ["Education", "Experience", "Projects", "Core Skills", "Awards", "Volunteering"])
    }

    // MARK: Visibility

    @Test func aHiddenSectionAndItsContentAreAbsent() {
        var style = LaTeXStyle.default
        style.hiddenSections = [.projects]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        #expect(!tex.contains("\\cvsection{Projects}"))
        #expect(!tex.contains("Formulator Pro"))          // the body goes too, not just the header
        #expect(emittedSections(tex) == ["Education", "Experience", "Core Skills", "Awards"])
    }

    /// The "no double gap" requirement, as byte equality: hiding a section produces **exactly** the
    /// document you'd get if that section had never been in the Markdown — no orphaned `\vspace`,
    /// which TeX would silently accumulate into the next section with no warning.
    @Test func hidingASectionLeavesTheSurroundingSpacingUntouched() {
        var style = LaTeXStyle.default
        style.hiddenSections = [.projects]

        #expect(TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)
            == TexDocumentBuilder.resume(fromMarkdown: fixtureWithoutProjects))
    }

    /// Hiding `.other` must not delete the lead paragraph — "Summary" classifies as `.other`, so a
    /// visibility filter applied one line too early would silently eat the user's opening prose.
    @Test func hidingOtherSectionsKeepsTheSummaryLead() {
        var style = LaTeXStyle.default
        style.hiddenSections = [.other]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        #expect(tex.contains("\\vspace{-0.5em}\n\\begin{justify}{\\paragraphstyle Mid-level iOS engineer"))
        #expect(!tex.contains("\\cvsection{Awards}"))
    }

    @Test func hidingEverySectionStillEmitsAValidDocument() {
        var style = LaTeXStyle.default
        style.hiddenSections = Set(LaTeXResumeSection.allCases)
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        #expect(tex.contains("\\begin{document}"))
        #expect(tex.contains("\\makecvheader"))
        #expect(tex.contains("\\paragraphstyle Mid-level iOS engineer"))   // the lead survives
        #expect(!tex.contains("\\cvsection{"))
        #expect(!tex.contains("\\begin{cventries}"))
        #expect(!tex.contains("\\begin{cvskills}"))
        #expect(tex.hasSuffix("\\end{document}\n"))
    }

    /// Hiding a bucket the document doesn't have changes nothing — and, unlike a bare equality
    /// between two identical calls (which would pass even with visibility unimplemented), this
    /// pins the surviving sections too.
    @Test func hidingABucketThatIsAbsentLeavesEveryOtherSectionInPlace() {
        var style = LaTeXStyle.default
        style.hiddenSections = [.projects]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixtureWithoutProjects, style: style)

        #expect(tex == TexDocumentBuilder.resume(fromMarkdown: fixtureWithoutProjects))
        #expect(emittedSections(tex) == ["Education", "Experience", "Core Skills", "Awards"])
    }

    // MARK: Spacing

    @Test func defaultStyleEmitsTheHandAuthoredVSpacePerSection() {
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture)
        #expect(tex.contains("\\vspace{-1em}\n\\cvsection{Education}"))
        #expect(tex.contains("\\vspace{-1.5em}\n\\cvsection{Experience}"))
        #expect(tex.contains("\\vspace{-1.5em}\n\\cvsection{Projects}"))
        #expect(tex.contains("\\vspace{-0.5em}\n\\cvsection{Core Skills}"))
        #expect(tex.contains("\\vspace{-1em}\n\\cvsection{Awards}"))
    }

    @Test func perSectionVSpaceComesFromTheStyle() {
        var style = LaTeXStyle.default
        style.sectionSpacingEm = [.experience: -2.25, .skills: 0]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        #expect(tex.contains("\\vspace{-2.25em}\n\\cvsection{Experience}"))
        #expect(tex.contains("\\vspace{0em}\n\\cvsection{Core Skills}"))    // not "-0em"
    }

    @Test func aSpacingMapMissingABucketFallsBackToTheCanonicalValueInTheTex() {
        var style = LaTeXStyle.default
        style.sectionSpacingEm = [.experience: -2]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        #expect(tex.contains("\\vspace{-2em}\n\\cvsection{Experience}"))
        #expect(tex.contains("\\vspace{-1em}\n\\cvsection{Education}"))
        #expect(tex.contains("\\vspace{-0.5em}\n\\cvsection{Core Skills}"))
        #expect(tex.contains("\\vspace{-1em}\n\\cvsection{Awards}"))
    }

    /// The lead paragraph keeps its own hardcoded `-0.5em`; it is not a section and the style has
    /// no field for it.
    @Test func theSummaryLeadKeepsItsOwnSpacing() {
        var style = LaTeXStyle.default
        style.sectionSpacingEm = [.other: -3]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        #expect(tex.contains("\\vspace{-0.5em}\n\\begin{justify}"))
        #expect(tex.contains("\\vspace{-3em}\n\\cvsection{Awards}"))
    }

    // MARK: The divergence from the pre-v0.7.0 builder

    /// "Employment" / "Work History" sorted as *experience* but were spaced as "other" (`-1em`) by
    /// the old builder, because its two classifiers disagreed. One bucket per section now, so they
    /// take the experience `-1.5em`. This is the **only** default-style change C makes to the
    /// emitted document, and this test is where it's visible.
    @Test(arguments: ["Employment", "Work History"])
    func experienceSynonymsTakeTheExperienceSpacingInTheEmittedTex(title: String) {
        let markdown = """
        # Taylor J. Larrechea

        ## Education
        ### B.S. Physics
        Utah · 2019
        - Graduated.

        ## \(title)
        ### iOS Engineer
        Lehi, UT · 2025 – Present
        - Shipped things.

        ## Core Skills
        iOS: SwiftUI
        """
        let tex = TexDocumentBuilder.resume(fromMarkdown: markdown)

        // Pre-v0.7.0 this line read `\vspace{-1em}` for these titles.
        #expect(tex.contains("\\vspace{-1.5em}\n\\cvsection{\(title)}"))
        #expect(emittedSections(tex) == ["Education", title, "Core Skills"])
    }

    /// The title-vs-bucket split is deliberate: "Educational Qualifications" **sorts** as education
    /// (the style's bucket) but **renders** as a skills grid (the title heuristic). Recorded so a
    /// later refactor doesn't "unify" the two and silently change how sections render.
    @Test func aTitleTheClassifiersDisagreeOnSortsByBucketAndRendersByTitle() {
        let markdown = """
        # Taylor J. Larrechea

        ## Experience
        ### iOS Engineer
        Lehi, UT · 2025 – Present
        - Shipped things.

        ## Educational Qualifications
        Physics: B.S. University of Utah
        """
        let tex = TexDocumentBuilder.resume(fromMarkdown: markdown)

        #expect(emittedSections(tex) == ["Educational Qualifications", "Experience"])   // sorts first
        #expect(tex.contains("\\begin{cvskills}"))                                     // renders as a grid
    }

    // MARK: The skills grid's \arraystretch stays inside its own group

    /// `\renewcommand{\arraystretch}{0.7}` used to be emitted ungrouped, so it stayed in force to
    /// `\end{document}` and compressed every later `tabular*` — i.e. every `\cventry` after the
    /// skills section. Invisible while skills sat last by construction; Milestone C made the order
    /// the user's, so "move skills up" silently restyled unrelated sections.
    ///
    /// Measured under `lualatex` on this fixture: ungrouped, the following entry's title→bullet gap
    /// compressed to **6.99pt**; grouped, it is **10.86pt** — matching a document with no skills
    /// grid at all (10.859pt) to within a hundredth of a point.
    @Test func theSkillsGridsArrayStretchIsScopedToItsOwnGroup() throws {
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture)
        #expect(tex.contains("{\\renewcommand{\\arraystretch}{0.7}\n\\begin{cvskills}"))
        #expect(tex.contains("\\end{cvskills}}"))

        // The group closes before anything else is emitted — nothing after the grid inherits it.
        let grid = try #require(tex.range(of: "{\\renewcommand{\\arraystretch}{0.7}"))
        let close = try #require(tex.range(of: "\\end{cvskills}}"))
        #expect(grid.lowerBound < close.lowerBound)
        #expect(TexDocumentBuilder.renderSkills([.paragraph(text: "iOS: SwiftUI")]).hasPrefix("{"))
        #expect(TexDocumentBuilder.renderSkills([.paragraph(text: "iOS: SwiftUI")]).hasSuffix("}\n"))
    }

    /// The reordered case the fix exists for: skills first, then an entries section.
    @Test func aSectionAfterTheSkillsGridIsOutsideItsGroup() throws {
        var style = LaTeXStyle.default
        style.sectionOrder = [.skills, .experience, .education, .projects, .other]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        let close = try #require(tex.range(of: "\\end{cvskills}}"))
        let nextSection = try #require(tex.range(of: "\\cvsection{Experience}"))
        #expect(close.upperBound < nextSection.lowerBound)
    }

    // MARK: Goldens

    /// Captured from the builder **before** Milestone C touched it, over a fixture covering every
    /// canonical bucket plus an unknown one. Milestone B's golden has one section per bucket, so
    /// this is what proves ordering, spacing and rendering are all unchanged by default.
    ///
    /// One documented amendment since (v0.7.0 Milestone E): the skills grid's `\arraystretch` is
    /// wrapped in a `{…}` group, so those two lines gained a brace and the **Awards** section that
    /// follows the grid regained the row height the leak had been compressing. Deliberate and
    /// measured; nothing else in this capture moved.
    private let goldenDefaultSections = #"""
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
    \begin{justify}{\paragraphstyle Mid-level iOS engineer shipping production SwiftUI features.}\end{justify}

    \vspace{-1em}
    \cvsection{Education}

    \begin{cventries}

        \cventry
        {B.S. Physics}
        {University of Utah}
        {Salt Lake City, UT}
        {2019}
        {
        \begin{cvitems}
            \item {Graduated with honours.}
        \end{cvitems}
        }

    \end{cventries}

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

    \vspace{-1.5em}
    \cvsection{Projects}

    \begin{cventries}

        \cvprojectsolo
        {Formulator Pro}
        {
        \begin{cvitems}
            \item {Cross-platform Electron app.}
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

    \vspace{-1em}
    \cvsection{Awards}

    \begin{cventries}

        \cventrysolo
        {Employee of the Year}
        {NRG Energy}
        {2025}
        {
        \begin{cvitems}
            \item {Recognised for the SwiftUI rewrite.}
        \end{cvitems}
        }

    \end{cventries}

    \end{document}

    """#

    @Test func defaultStyleGoldenCoversEveryCanonicalBucket() {
        #expect(TexDocumentBuilder.resume(fromMarkdown: fixture) == goldenDefaultSections)
    }

    /// A change-detector for the **new** behaviour (captured after the change, unlike the golden
    /// above): a reordered, partly hidden résumé. It proves the shape stays stable, not that
    /// nothing regressed.
    @Test func aReorderedAndPartlyHiddenResumeIsStable() {
        var style = LaTeXStyle.default
        style.sectionOrder = [.skills, .experience]
        style.hiddenSections = [.projects]
        let tex = TexDocumentBuilder.resume(fromMarkdown: fixture, style: style)

        #expect(emittedSections(tex) == ["Core Skills", "Experience", "Awards", "Education"])
        #expect(!tex.contains("Formulator Pro"))
        #expect(tex.contains("\\vspace{-0.5em}\n\\cvsection{Core Skills}"))
        #expect(tex.contains("\\vspace{-1.5em}\n\\cvsection{Experience}"))
        #expect(tex.contains("\\vspace{-1em}\n\\cvsection{Awards}"))
        #expect(tex.contains("\\vspace{-1em}\n\\cvsection{Education}"))
    }

    /// The converse of `bodyIsIdenticalAcrossStyles`: the three section fields never reach the
    /// preamble.
    @Test func sectionFieldsNeverAffectThePreamble() {
        var style = LaTeXStyle.default
        style.sectionOrder = [.skills, .experience]
        style.hiddenSections = [.projects, .other]
        style.sectionSpacingEm = [.experience: -3]

        func preamble(_ tex: String) -> String {
            guard let range = tex.range(of: "\\begin{document}") else { return tex }
            return String(tex[tex.startIndex..<range.lowerBound])
        }
        #expect(preamble(TexDocumentBuilder.resume(fromMarkdown: fixture, style: style))
            == preamble(TexDocumentBuilder.resume(fromMarkdown: fixture)))
    }

    /// The cover letter has no sections in the style's sense — its `\lettersection`s are the
    /// user's prose in document order and must never be reordered or dropped.
    @Test func theCoverLetterIgnoresSectionOrderAndVisibility() {
        let letter = """
        ## About Me
        My name is Taylor.

        ## Why Acme
        Your gateway work matches mine.

        ## Why Me
        I ship fast.
        """
        var style = LaTeXStyle.default
        style.sectionOrder = [.skills, .experience]
        style.hiddenSections = Set(LaTeXResumeSection.allCases)
        let tex = TexDocumentBuilder.coverLetter(fromMarkdown: letter, style: style)

        let titles = tex.components(separatedBy: "\\lettersection{").dropFirst().compactMap { chunk in
            chunk.firstIndex(of: "}").map { String(chunk[chunk.startIndex..<$0]) }
        }
        #expect(titles == ["About Me", "Why Acme", "Why Me"])
    }

    // MARK: Integration — a reordered, partly hidden résumé still compiles

    @Test func aReorderedAndHiddenResumeCompilesUnderLualatex() async throws {
        let client = LaTeXProcessClient()
        guard client.isAvailable, client.assets?.isComplete == true else {
            return   // no TeX install / assets — don't fail the suite
        }
        var style = LaTeXStyle.default
        style.sectionOrder = [.skills, .experience, .education, .projects, .other]
        style.hiddenSections = [.other]

        let pdf = try await client.compile(
            tex: TexDocumentBuilder.resume(fromMarkdown: fixture, style: style), jobName: "reordered resume")
        #expect(pdf.prefix(4).elementsEqual(Data("%PDF".utf8)))
    }
}
