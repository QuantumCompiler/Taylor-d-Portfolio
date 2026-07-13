//
//  TexDocumentBuilder.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Tex — render generated Markdown into awesome-cv LaTeX (Milestone C).
//

import Foundation

/// Renders the generated résumé / cover-letter **Markdown** into `.tex` that drives Taylor's
/// bundled awesome-cv classes (the inverse of the repo's `tex2docx.py`). Pure and
/// domain-agnostic — Markdown `String` in, `.tex` `String` out — so it's fully unit-testable
/// and never imports upward. Reuses the shared `MarkdownBlockParser` / `MarkdownInline`.
///
/// **Fidelity (C-parse):** the output mirrors the **exact macro structure, section order, and
/// spacing** of Taylor's hand-authored résumé — `\begin{cventries}` + `\cventry`/`\cvproject`
/// wrapped entries, the Education → Experience → Projects → Qualifications order, the per-section
/// `\vspace` tweaks, and `\arraystretch` before the skills grid — so generated content adopts the
/// same look. The generated Markdown is loose (no explicit org/location/date fields), so entry
/// metadata is split heuristically from the "Title — Org" / "Location · Date" shapes the app's own
/// generation produces. All interpolated text is LaTeX-escaped; only the FontAwesome icons already
/// in the classes are used (none are introduced), so the output compiles under `lualatex`.
nonisolated enum TexDocumentBuilder {

    // MARK: Public API (mirrors the DocumentExporter shape: Markdown in, .tex out)

    /// A complete résumé `.tex` document driving `Class/Resume`.
    static func resume(fromMarkdown markdown: String) -> String {
        let blocks = MarkdownBlockParser.blocks(from: markdown)
        let level = sectionLevel(of: blocks)
        let (preamble, sections) = split(blocks, atHeadingLevel: level)

        // A "Summary/Profile" section renders as a lead paragraph (the résumé opens with prose,
        // not a titled section); the rest sort into the canonical résumé order.
        let contentSections = sections.filter { !isSummarySection($0.title) }
        let ordered = contentSections.enumerated()
            .sorted { (canonicalOrder($0.element.title), $0.offset) < (canonicalOrder($1.element.title), $1.offset) }
            .map(\.element)

        var body = "\\makecvheader\n\n"
        if let lead = leadSummary(preamble: preamble, sections: sections) {
            body += "\\vspace{-0.5em}\n\\begin{justify}{\\paragraphstyle \(inlineLaTeX(lead))}\\end{justify}\n\n"
        }
        for section in ordered {
            body += "\\vspace{\(sectionVSpace(section.title))}\n\\cvsection{\(plainLaTeX(section.title))}\n\n"
            body += isSkillsSection(section.title) ? renderSkills(section.blocks) : renderEntries(section.blocks)
            body += "\n"
        }
        return resumePreamble(headline: headline(in: preamble)) + "\\begin{document}\n\n" + body + "\\end{document}\n"
    }

    /// A complete cover-letter `.tex` document driving `Class/CoverLetter`.
    static func coverLetter(fromMarkdown markdown: String) -> String {
        let blocks = MarkdownBlockParser.blocks(from: markdown)
        let (preamble, sections) = split(blocks, atHeadingLevel: sectionLevel(of: blocks))

        var letter = ""
        for case let .paragraph(text) in preamble where !isContactLine(text) {
            letter += "\(inlineLaTeX(text))\n\n"
        }
        for section in sections {
            letter += "\\lettersection{\(plainLaTeX(section.title))}\n\n"
            for case let .paragraph(text) in section.blocks {
                letter += "\(inlineLaTeX(text))\n\n"
            }
        }

        return coverLetterPreamble(headline: headline(in: preamble))
            + "\\begin{document}\n\n\\makecvheader\n\n"
            + "\\setlength{\\parskip}{1.0em}\n\\linespread{1.08}\\selectfont\n\n"
            + "\\begin{cvletter}\n\n\(letter)\\end{cvletter}\n\n"
            + "\\makeletterclosing\n\n\\end{document}\n"
    }

    // MARK: Section model + splitting

    struct Section: Equatable {
        var title: String
        var blocks: [MarkdownBlock]
    }

    /// The heading level that denotes sections — H2 when any exist, else H1.
    static func sectionLevel(of blocks: [MarkdownBlock]) -> Int {
        blocks.contains { if case .heading(2, _) = $0 { return true }; return false } ? 2 : 1
    }

    /// Splits blocks into the leading preamble (before the first section) and one ``Section`` per
    /// heading at exactly `level`. Headings above `level` (an H1 name) stay in the preamble;
    /// headings below `level` (H3 entries) fall inside their section.
    static func split(_ blocks: [MarkdownBlock], atHeadingLevel level: Int) -> (preamble: [MarkdownBlock], sections: [Section]) {
        var preamble: [MarkdownBlock] = []
        var sections: [Section] = []
        var current: Section?
        for block in blocks {
            if case let .heading(headingLevel, text) = block, headingLevel == level {
                if let open = current { sections.append(open) }
                current = Section(title: text, blocks: [])
            } else if current != nil {
                current?.blocks.append(block)
            } else {
                preamble.append(block)
            }
        }
        if let open = current { sections.append(open) }
        return (preamble, sections)
    }

    // MARK: Résumé section rendering

    /// A section of dated/roled entries → `\begin{cventries}` with `\cventry` / `\cvproject`
    /// (or their dash-free `…solo` variants) per entry — matching the hand-authored résumé.
    static func renderEntries(_ blocks: [MarkdownBlock]) -> String {
        let (entries, leadingProse) = parseEntries(blocks)
        var out = ""
        for prose in leadingProse {
            out += "\\begin{justify}{\\paragraphstyle \(inlineLaTeX(prose))}\\end{justify}\n\n"
        }
        guard !entries.isEmpty else { return out }
        out += "\\begin{cventries}\n\n"
        for entry in entries { out += renderEntry(entry) }
        out += "\\end{cventries}\n"
        return out
    }

    private static func renderEntry(_ entry: Entry) -> String {
        let description = entry.items.isEmpty ? "{}" :
            "{\n    \\begin{cvitems}\n"
            + entry.items.map { "        \\item {\(inlineLaTeX($0))}\n" }.joined()
            + "    \\end{cvitems}\n    }"

        if let subtitle = entry.subtitle, looksDated(subtitle) {
            let (location, date) = splitLocationDate(subtitle)
            if let (position, organization) = splitOnSeparator(entry.title) {
                return "    \\cventry\n    {\(plainLaTeX(position))}\n    {\(plainLaTeX(organization))}\n"
                    + "    {\(plainLaTeX(location))}\n    {\(plainLaTeX(date))}\n    \(description)\n\n"
            }
            return "    \\cventrysolo\n    {\(plainLaTeX(entry.title))}\n"
                + "    {\(plainLaTeX(location))}\n    {\(plainLaTeX(date))}\n    \(description)\n\n"
        }
        if let role = entry.subtitle {          // a non-dated subtitle reads as a role
            return "    \\cvproject\n    {\(plainLaTeX(role))}\n    {\(plainLaTeX(entry.title))}\n    \(description)\n\n"
        }
        return "    \\cvprojectsolo\n    {\(plainLaTeX(entry.title))}\n    \(description)\n\n"
    }

    /// A section rendered as `cvskills` (with the résumé's `\arraystretch{0.7}`) — each non-empty
    /// line becomes a `\cvskill{bucket}{items}` (split on the first ": ").
    static func renderSkills(_ blocks: [MarkdownBlock]) -> String {
        let lines: [String] = blocks.compactMap {
            switch $0 {
            case let .paragraph(text): return text
            case let .bullet(text): return text
            default: return nil
            }
        }
        guard !lines.isEmpty else { return "" }
        var rows = ""
        for line in lines {
            if let range = line.range(of: ": ") {
                rows += "    \\cvskill\n    {\(plainLaTeX(String(line[line.startIndex..<range.lowerBound])))}\n"
                    + "    {\(inlineLaTeX(String(line[range.upperBound...])))}\n"
            } else {
                rows += "    \\cvskill\n    {}\n    {\(inlineLaTeX(line))}\n"
            }
        }
        return "\\renewcommand{\\arraystretch}{0.7}\n\\begin{cvskills}\n\(rows)\\end{cvskills}\n"
    }

    // MARK: Entry parsing

    struct Entry: Equatable {
        var title: String
        var subtitle: String?
        var items: [String]
    }

    /// Groups a section's blocks into entries: a heading or fully-bold paragraph opens an entry
    /// (its title); the next plain paragraph is its subtitle (location · date, or a role); bullets
    /// are its items. Paragraphs before any entry are returned as leading prose.
    static func parseEntries(_ blocks: [MarkdownBlock]) -> (entries: [Entry], leadingProse: [String]) {
        var entries: [Entry] = []
        var leadingProse: [String] = []
        var current: Entry?
        func flush() { if let open = current { entries.append(open); current = nil } }

        for block in blocks {
            switch block {
            case let .heading(_, text):
                flush(); current = Entry(title: text, subtitle: nil, items: [])
            case let .paragraph(text) where isBold(text):
                flush(); current = Entry(title: plainBold(text), subtitle: nil, items: [])
            case let .paragraph(text):
                if current != nil, current?.subtitle == nil, current?.items.isEmpty == true {
                    current?.subtitle = text
                } else if current == nil {
                    leadingProse.append(text)
                }
            case let .bullet(text):
                if current == nil { current = Entry(title: "", subtitle: nil, items: []) }
                current?.items.append(text)
            case .thematicBreak, .blank:
                break
            }
        }
        flush()
        return (entries, leadingProse)
    }

    // MARK: Ordering / spacing (to match the hand-authored résumé)

    /// The canonical résumé section order: Education, Experience, Projects, Qualifications/Skills,
    /// then anything else (stable). Mirrors the manual `Resume.tex` `\input` order.
    static func canonicalOrder(_ title: String) -> Int {
        let lower = title.lowercased()
        if lower.contains("education") { return 0 }
        if lower.contains("experience") || lower.contains("employment") || lower.contains("work history") { return 1 }
        if lower.contains("project") { return 2 }
        if isSkillsSection(title) { return 3 }
        return 4
    }

    /// The `\vspace` before each `\cvsection`, matching the hand-authored section files.
    static func sectionVSpace(_ title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("education") { return "-1em" }
        if lower.contains("experience") || lower.contains("project") { return "-1.5em" }
        if isSkillsSection(title) { return "-0.5em" }
        return "-1em"
    }

    /// The lead summary text — a preamble summary, or the prose of a "Summary/Profile" section.
    static func leadSummary(preamble: [MarkdownBlock], sections: [Section]) -> String? {
        if let fromPreamble = summary(in: preamble) { return fromPreamble }
        let prose = sections.filter { isSummarySection($0.title) }.flatMap { section in
            section.blocks.compactMap { if case let .paragraph(text) = $0 { return text }; return nil }
        }.joined(separator: " ")
        return prose.isEmpty ? nil : prose
    }

    // MARK: Preambles

    private static func resumePreamble(headline: String?) -> String {
        var out = """
        \\documentclass[6pt]{Class/Resume}
        \\geometry{left=0.50cm, top=0.50cm, right=0.50cm, bottom=0.75cm, footskip=0.25cm}
        \\nonstopmode
        \\fontdir[fonts/]
        \\pageHeader

        """
        if let headline, !headline.isEmpty { out += "\\position{\(plainLaTeX(headline))}\n" }
        out += "\\pageFooter{Résumé}\n\n"
        out += Self.entryHelpers + "\n"
        return out
    }

    /// Dash-free variants of the class's `\cventry` / `\cvproject` (identical spacing, minus the
    /// mandatory "org — position" dash) for entries where the generated Markdown supplies only a
    /// title. Built from the same class style commands, so the layout matches exactly.
    private static let entryHelpers = """
    % Generated helpers (Taylor'd Portfolio): dash-free entry rows with awesome-cv spacing.
    \\newcommand{\\cventrysolo}[4]{%
      \\vspace{-2.0mm}\\setlength\\tabcolsep{0pt}\\setlength{\\extrarowheight}{0pt}%
      \\begin{tabular*}{\\textwidth}{@{\\extracolsep{\\fill}} L{\\dimexpr\\textwidth-6.0cm} r}%
        \\entrytitlestyle{#1} & {\\entrylocationstyle{#2}\\entrydatestyle{ - #3}} \\\\%
        \\multicolumn{2}{L{\\textwidth}}{\\vspace{0mm}\\descriptionstyle{#4}}%
      \\end{tabular*}%
    }
    \\newcommand{\\cvprojectsolo}[2]{%
      \\vspace{-2.0mm}\\setlength\\tabcolsep{0pt}\\setlength{\\extrarowheight}{0pt}%
      \\begin{tabular*}{\\textwidth}{@{\\extracolsep{\\fill}} L{\\textwidth}}%
        \\entrytitlestyle{#1} \\\\%
        \\multicolumn{1}{L{\\textwidth}}{\\descriptionstyle{#2}}%
      \\end{tabular*}%
    }
    """

    private static func coverLetterPreamble(headline: String?) -> String {
        var out = """
        \\documentclass[11pt, a4paper]{Class/CoverLetter}
        \\geometry{left=0.50cm, top=0.50cm, right=0.50cm, bottom=0.75cm, footskip=0.25cm}
        \\nonstopmode
        \\fontdir[fonts/]
        \\pageHeader

        """
        if let headline, !headline.isEmpty { out += "\\position{\(plainLaTeX(headline))}\n" }
        out += "\\pageFooter{Cover Letter}\n\n"
        return out
    }

    // MARK: Preamble extraction

    /// The role headline for `\position` — the first fully-bold paragraph in the preamble (the
    /// generated résumé opens with one), else the first heading's text. Contact lines are skipped.
    static func headline(in preamble: [MarkdownBlock]) -> String? {
        for block in preamble {
            if case let .paragraph(text) = block, isBold(text), !isContactLine(text) {
                return plainBold(text)
            }
        }
        for block in preamble {
            if case let .heading(_, text) = block { return text }
        }
        return nil
    }

    /// The summary paragraph(s) in the preamble (not the bold headline or a contact line), joined.
    static func summary(in preamble: [MarkdownBlock]) -> String? {
        let parts: [String] = preamble.compactMap {
            guard case let .paragraph(text) = $0, !isBold(text), !isContactLine(text) else { return nil }
            return text
        }
        let joined = parts.joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }

    // MARK: LaTeX escaping + inline

    /// Escapes the LaTeX special characters so arbitrary text is safe in the document body.
    static func escape(_ string: String) -> String {
        var out = ""
        out.reserveCapacity(string.count)
        for character in string {
            switch character {
            case "\\": out += "\\textbackslash{}"
            case "&": out += "\\&"
            case "%": out += "\\%"
            case "$": out += "\\$"
            case "#": out += "\\#"
            case "_": out += "\\_"
            case "{": out += "\\{"
            case "}": out += "\\}"
            case "~": out += "\\textasciitilde{}"
            case "^": out += "\\textasciicircum{}"
            default: out.append(character)
            }
        }
        return out
    }

    /// Renders inline Markdown (**bold** / *italic* / links) to escaped LaTeX with `\textbf` /
    /// `\textit`. Reuses the shared `MarkdownInline` run splitter (links collapse to their text).
    static func inlineLaTeX(_ text: String) -> String {
        MarkdownInline.runs(from: text).map { run in
            let escaped = escape(run.text)
            switch (run.bold, run.italic) {
            case (true, true): return "\\textbf{\\textit{\(escaped)}}"
            case (true, false): return "\\textbf{\(escaped)}"
            case (false, true): return "\\textit{\(escaped)}"
            case (false, false): return escaped
            }
        }.joined()
    }

    /// Escaped plain text with inline markers stripped — for titles/headings a class style bolds.
    static func plainLaTeX(_ text: String) -> String {
        escape(MarkdownInline.runs(from: text).map(\.text).joined())
    }

    // MARK: Small heuristics

    /// Whether a section title reads as a skills/qualifications list (→ rendered as `cvskills`).
    static func isSkillsSection(_ title: String) -> Bool {
        let lower = title.lowercased()
        return lower.contains("skill") || lower.contains("qualification") || lower.contains("competenc")
    }

    /// Whether a section title reads as a summary/profile intro (→ rendered as a lead paragraph).
    static func isSummarySection(_ title: String) -> Bool {
        let lower = title.lowercased()
        return lower.contains("summary") || lower.contains("profile") || lower == "about"
    }

    /// Whether a subtitle carries date-like content (a 4-digit year or "Present") → an entry with
    /// a location/date row (`\cventry`) rather than a role (`\cvproject`).
    static func looksDated(_ text: String) -> Bool {
        if text.lowercased().contains("present") { return true }
        return text.range(of: "(19|20)[0-9]{2}", options: .regularExpression) != nil
    }

    /// Splits `title` on the first location/role separator into (before, after), trimmed.
    static func splitOnSeparator(_ text: String) -> (String, String)? {
        for separator in [" — ", " – ", " - ", " | ", " · "] {
            if let range = text.range(of: separator) {
                let before = text[text.startIndex..<range.lowerBound].trimmingCharacters(in: .whitespaces)
                let after = text[range.upperBound...].trimmingCharacters(in: .whitespaces)
                return (before, after)
            }
        }
        return nil
    }

    /// Splits a "Location · Date" subtitle into (location, date). Uses **only** the middot / pipe
    /// separators — never a dash — because a date range itself contains a dash ("2025 – Present").
    /// An unsplit subtitle is treated as all date (dates are the common single field on a dated row).
    static func splitLocationDate(_ subtitle: String) -> (location: String, date: String) {
        for separator in [" · ", " | ", " • ", "·", "|"] {
            if let range = subtitle.range(of: separator) {
                return (subtitle[subtitle.startIndex..<range.lowerBound].trimmingCharacters(in: .whitespaces),
                        subtitle[range.upperBound...].trimmingCharacters(in: .whitespaces))
            }
        }
        return ("", subtitle)
    }

    /// Whether every inline run of `text` is bold (a fully-bold "lead" line).
    static func isBold(_ text: String) -> Bool {
        let runs = MarkdownInline.runs(from: text)
        return !runs.isEmpty
            && runs.allSatisfy { $0.bold || $0.text.trimmingCharacters(in: .whitespaces).isEmpty }
            && runs.contains { $0.bold }
    }

    /// A fully-bold paragraph's plain text (markers stripped).
    static func plainBold(_ text: String) -> String {
        MarkdownInline.runs(from: text).map(\.text).joined()
    }

    /// A contact line the class header already renders (so we drop it): an email address or a
    /// pipe-separated list of labelled contact fields.
    static func isContactLine(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.contains("@") && lower.contains(".") { return true }
        let labels = ["mobile:", "email:", "phone:", "github:", "linkedin:", "web:", "www."]
        return labels.filter { lower.contains($0) }.count >= 2
    }
}
