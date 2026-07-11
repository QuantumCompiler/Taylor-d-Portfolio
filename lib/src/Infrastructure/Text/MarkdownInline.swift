//
//  MarkdownInline.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Text — split inline Markdown into styled runs (for OOXML/DOCX).
//

import Foundation

/// A run of inline text with its emphasis, extracted from Markdown.
nonisolated struct MarkdownInlineRun: Equatable, Sendable {
    var text: String
    var bold: Bool = false
    var italic: Bool = false
}

/// Splits inline Markdown into `MarkdownInlineRun`s using Foundation's own inline Markdown
/// parser (the same engine the PDF renderer relies on), so **bold**/*italic*/`code`/links are
/// interpreted consistently. Link syntax collapses to its display text; code spans render as
/// plain text.
nonisolated enum MarkdownInline {
    static func runs(from text: String) -> [MarkdownInlineRun] {
        guard let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return [MarkdownInlineRun(text: text)]
        }
        var result: [MarkdownInlineRun] = []
        for run in attributed.runs {
            let piece = String(attributed[run.range].characters)
            guard !piece.isEmpty else { continue }
            let intent = run.inlinePresentationIntent ?? []
            result.append(MarkdownInlineRun(
                text: piece,
                bold: intent.contains(.stronglyEmphasized),
                italic: intent.contains(.emphasized)
            ))
        }
        // Never return empty for non-empty input (e.g. whitespace-only): fall back to plain.
        return result.isEmpty ? [MarkdownInlineRun(text: text)] : result
    }
}
