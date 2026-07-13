//
//  MarkdownBlockParser.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Text — classify Markdown lines into block types (shared by exporters).
//

import Foundation

/// One block-level element of a Markdown document, at the fidelity our exporters target.
nonisolated enum MarkdownBlock: Equatable, Sendable {
    case heading(level: Int, text: String)
    case bullet(text: String)
    case paragraph(text: String)
    /// A horizontal rule / section separator — a whole line of 3+ `-`, `*`, or `_`.
    case thematicBreak
    case blank
}

/// Classifies Markdown into block-level elements, line by line. The single source of truth
/// for block detection shared by the PDF (`MarkdownAttributedRenderer`) and DOCX
/// (`OOXMLDocument`) exporters, so they never drift. Inline syntax is handled separately
/// (see ``MarkdownInline``).
nonisolated enum MarkdownBlockParser {
    static func blocks(from markdown: String) -> [MarkdownBlock] {
        markdown.components(separatedBy: "\n").map(classify)
    }

    static func classify(_ line: String) -> MarkdownBlock {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .blank }

        let unindented = line.drop { $0 == " " }

        // Heading: 1–6 leading '#' followed by a space.
        var level = 0
        var rest = Substring(unindented)
        while rest.first == "#" { level += 1; rest = rest.dropFirst() }
        if (1...6).contains(level), rest.first == " " {
            return .heading(level: level, text: rest.trimmingCharacters(in: .whitespaces))
        }

        // Thematic break: a whole line of 3+ of the same marker ('-', '*', '_'), with
        // optional spaces between. Checked *before* the bullet rule so "- - -" / "***"
        // aren't misread as bullets (a bullet needs a marker + space + text).
        if isThematicBreak(trimmed) { return .thematicBreak }

        // Bullet: '-', '*', or '+' followed by a space.
        if let marker = unindented.first, "-*+".contains(marker), unindented.dropFirst().first == " " {
            return .bullet(text: unindented.dropFirst().trimmingCharacters(in: .whitespaces))
        }

        return .paragraph(text: line)
    }

    /// Whether `trimmed` (already whitespace-trimmed, non-empty) is a Markdown thematic break:
    /// 3+ of a single marker character (`-`, `*`, or `_`), spaces/tabs allowed between them and
    /// nothing else. e.g. `---`, `***`, `___`, `- - -`.
    static func isThematicBreak(_ trimmed: String) -> Bool {
        let compact = trimmed.filter { $0 != " " && $0 != "\t" }
        guard compact.count >= 3, let marker = compact.first, "-*_".contains(marker) else { return false }
        return compact.allSatisfy { $0 == marker }
    }
}
