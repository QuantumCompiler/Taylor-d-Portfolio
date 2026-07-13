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
/// **C-parse (Milestone C):** a *best-effort* structural map — the generated Markdown is loose
/// (no explicit org/location/date fields), so entry metadata is only as rich as the Markdown
/// carries. Full-fidelity structured generation is the flagged C-structured fast-follow. All
/// interpolated text is LaTeX-escaped and only the FontAwesome icons already in the classes are
/// used (none are introduced), so the output compiles under `lualatex`.
nonisolated enum TexDocumentBuilder {

    // MARK: Public API (mirrors the DocumentExporter shape: Markdown in, .tex out)

    /// A complete résumé `.tex` document driving `Class/Resume`.
    static func resume(fromMarkdown markdown: String) -> String {
        let blocks = MarkdownBlockParser.blocks(from: markdown)
        let sectionLevel = blocks.contains { if case .heading(2, _) = $0 { return true }; return false } ? 2 : 1
        let (preamble, sections) = split(blocks, atHeadingLevel: sectionLevel)
        let head = resumePreamble(headline: headline(in: preamble))

        var body = "\\makecvheader\n"
        if let summary = summary(in: preamble) {
            body += "\\vspace{-0.5em}\n\\begin{justify}{\\paragraphstyle \(inlineLaTeX(summary))}\\end{justify}\n\n"
        }
        for section in sections {
            body += renderResumeSection(section)
        }
        return head + "\\begin{document}\n\n" + body + "\n\\end{document}\n"
    }

    /// A complete cover-letter `.tex` document driving `Class/CoverLetter`.
    static func coverLetter(fromMarkdown markdown: String) -> String {
        let blocks = MarkdownBlockParser.blocks(from: markdown)
        let sectionLevel = blocks.contains { if case .heading(2, _) = $0 { return true }; return false } ? 2 : 1
        let (preamble, sections) = split(blocks, atHeadingLevel: sectionLevel)

        var letter = ""
        // Any intro prose before the first heading is emitted straight into the letter.
        for case let .paragraph(text) in preamble where !isContactLine(text) {
            letter += "\(inlineLaTeX(text))\n\n"
        }
        for section in sections {
            letter += "\\lettersection{\(plainLaTeX(section.title))}\n\n"
            for case let .paragraph(text) in section.blocks {
                letter += "\(inlineLaTeX(text))\n\n"
            }
        }

        let head = coverLetterPreamble(headline: headline(in: preamble))
        return head
            + "\\begin{document}\n\n\\makecvheader\n\n"
            + "\\setlength{\\parskip}{1.0em}\n\\linespread{1.08}\\selectfont\n\n"
            + "\\begin{cvletter}\n\n\(letter)\\end{cvletter}\n\n"
            + "\\makeletterclosing\n\n\\end{document}\n"
    }

    // MARK: Section model

    struct Section: Equatable {
        var title: String
        var blocks: [MarkdownBlock]
    }

    /// Splits blocks into the leading preamble (before the first section) and one ``Section`` per
    /// heading at exactly `level`. Headings *above* `level` (e.g. an H1 name when sections are H2)
    /// stay in the preamble — the class header already renders the name; headings *below* `level`
    /// (e.g. H3 entries) fall inside their section and drive entry parsing.
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

    private static func renderResumeSection(_ section: Section) -> String {
        var out = "\\cvsection{\(plainLaTeX(section.title))}\n\n"
        if isSkillsSection(section.title) {
            out += renderSkills(section.blocks)
        } else {
            out += renderEntries(section.blocks)
        }
        return out + "\n"
    }

    /// A section rendered as `cvskills` — each non-empty line becomes a `\cvskill{bucket}{items}`
    /// (split on the first ": "; a line with no colon becomes a bucket-less skill row).
    private static func renderSkills(_ blocks: [MarkdownBlock]) -> String {
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
                let bucket = String(line[line.startIndex..<range.lowerBound])
                let items = String(line[range.upperBound...])
                rows += "  \\cvskill{\(plainLaTeX(bucket))}{\(inlineLaTeX(items))}\n"
            } else {
                rows += "  \\cvskill{}{\(inlineLaTeX(line))}\n"
            }
        }
        return "\\begin{cvskills}\n\(rows)\\end{cvskills}\n"
    }

    /// A section rendered as a sequence of entries. An entry starts at a heading or a fully-bold
    /// paragraph (its title); the next plain paragraph becomes a subtitle (e.g. location · date);
    /// bullets become `\item`s. Loose paragraphs with no entry render as justified prose.
    private static func renderEntries(_ blocks: [MarkdownBlock]) -> String {
        var out = ""
        var title: String?
        var subtitle: String?
        var items: [String] = []
        var hasEntry = false

        func flush() {
            guard hasEntry else { return }
            if let title { out += "{\\entrytitlestyle{\(plainLaTeX(title))}}\\par\n" }
            if let subtitle { out += "{\\entrydatestyle{\(inlineLaTeX(subtitle))}}\\par\\vspace{0.3em}\n" }
            if !items.isEmpty {
                out += "\\begin{cvitems}\n"
                for item in items { out += "  \\item {\(inlineLaTeX(item))}\n" }
                out += "\\end{cvitems}\n"
            }
            out += "\n"
            title = nil; subtitle = nil; items = []; hasEntry = false
        }

        for block in blocks {
            switch block {
            case let .heading(_, text):
                flush(); title = text; hasEntry = true
            case let .paragraph(text) where isBold(text) && !hasEntry:
                flush(); title = plainBold(text); hasEntry = true
            case let .paragraph(text):
                if hasEntry && subtitle == nil && items.isEmpty {
                    subtitle = text
                } else {
                    // Prose with no entry context → a justified paragraph. `\paragraphstyle` is a
                    // 0-arg font switch, so the text follows it inside the group.
                    flush()
                    out += "\\begin{justify}{\\paragraphstyle \(inlineLaTeX(text))}\\end{justify}\n\n"
                }
            case let .bullet(text):
                hasEntry = true; items.append(text)
            case .thematicBreak, .blank:
                break
            }
        }
        flush()
        return out
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
        return out
    }

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

    /// The summary paragraph(s) — preamble paragraphs that aren't the bold headline or a contact
    /// line, joined. Empty when there's no summary.
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
    /// Char-by-char (each maps independently), so replacements are never re-escaped.
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

    /// Escaped plain text with inline markers stripped — for titles/headings that a class style
    /// already emphasises (so they aren't double-bolded).
    static func plainLaTeX(_ text: String) -> String {
        escape(MarkdownInline.runs(from: text).map(\.text).joined())
    }

    // MARK: Small heuristics

    /// Whether a section title reads as a skills/qualifications list (→ rendered as `cvskills`).
    static func isSkillsSection(_ title: String) -> Bool {
        let lower = title.lowercased()
        return lower.contains("skill") || lower.contains("qualification") || lower.contains("competenc")
    }

    /// Whether every inline run of `text` is bold (a fully-bold "lead" line).
    static func isBold(_ text: String) -> Bool {
        let runs = MarkdownInline.runs(from: text)
        return !runs.isEmpty && runs.allSatisfy { $0.bold || $0.text.trimmingCharacters(in: .whitespaces).isEmpty }
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
