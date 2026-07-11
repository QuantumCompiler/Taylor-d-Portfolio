//
//  MarkdownPlainText.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Text — reduce Markdown to readable plain text (for plain-text export).
//

import Foundation

/// Strips common Markdown syntax to plain, readable text — the counterpart to
/// ``HTMLStripper`` for the other direction. Pure and unit-tested.
///
/// Fidelity is intentionally simple: it targets the subset the generated résumé / cover
/// letter actually use (headings, bullets, bold/italic, inline code, links). Tables and
/// fenced code blocks are left largely as-is (their markers removed where cheap).
nonisolated enum MarkdownPlainText {
    static func plainText(from markdown: String) -> String {
        var s = markdown
        // Headings: drop the leading "#" markers, keep the text.
        s = s.replacingOccurrences(of: "(?m)^[ \\t]*#{1,6}[ \\t]+", with: "", options: .regularExpression)
        // Blockquotes: drop the leading ">".
        s = s.replacingOccurrences(of: "(?m)^[ \\t]*>[ \\t]?", with: "", options: .regularExpression)
        // Bullets (-, *, +) at line start become a bullet dot.
        s = s.replacingOccurrences(of: "(?m)^[ \\t]*[-*+][ \\t]+", with: "• ", options: .regularExpression)
        // Links [text](url) → text.
        s = s.replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^\\)]*\\)", with: "$1", options: .regularExpression)
        // Emphasis markers (**, __, *, _) removed.
        s = s.replacingOccurrences(of: "(\\*\\*|__|\\*|_)", with: "", options: .regularExpression)
        // Inline code backticks removed.
        s = s.replacingOccurrences(of: "`", with: "")
        // Collapse 3+ blank lines to a single blank line.
        s = s.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
