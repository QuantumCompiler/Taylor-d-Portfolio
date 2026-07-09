//
//  HTMLStripper.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Text — HTML → readable plain text.
//

import Foundation

/// Turns HTML markup into readable plain text. Domain-agnostic text plumbing, so it
/// lives in Infrastructure and can be used both by the Presentation layer (rendering
/// a job description) and by the Data layer (extracting a posting fetched from a URL).
///
/// A pure function — unit-tested without a view or network.
nonisolated enum HTMLStripper {
    static func plainText(_ html: String) -> String {
        var text = html
        // Turn line-breaking / block-closing tags into newlines before stripping.
        text = text.replacingOccurrences(of: "(?i)<br\\s*/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "(?i)</(p|div|li|h[1-6]|ul|ol)>", with: "\n", options: .regularExpression)
        // Drop script/style contents entirely (common in fetched pages).
        text = text.replacingOccurrences(of: "(?is)<(script|style)[^>]*>.*?</\\1>", with: " ", options: .regularExpression)
        // Strip every remaining tag.
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Decode the handful of entities job boards commonly emit.
        let entities = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
            "&#39;": "'", "&apos;": "'", "&nbsp;": " ",
        ]
        for (entity, char) in entities {
            text = text.replacingOccurrences(of: entity, with: char)
        }
        // Collapse runs of blank lines and trim.
        text = text.replacingOccurrences(of: "[ \\t]+\n", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
