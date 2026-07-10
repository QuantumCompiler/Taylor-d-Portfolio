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
        guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return .blank }

        let unindented = line.drop { $0 == " " }

        // Heading: 1–6 leading '#' followed by a space.
        var level = 0
        var rest = Substring(unindented)
        while rest.first == "#" { level += 1; rest = rest.dropFirst() }
        if (1...6).contains(level), rest.first == " " {
            return .heading(level: level, text: rest.trimmingCharacters(in: .whitespaces))
        }

        // Bullet: '-', '*', or '+' followed by a space.
        if let marker = unindented.first, "-*+".contains(marker), unindented.dropFirst().first == " " {
            return .bullet(text: unindented.dropFirst().trimmingCharacters(in: .whitespaces))
        }

        return .paragraph(text: line)
    }
}
