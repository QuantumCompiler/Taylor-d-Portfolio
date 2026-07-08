//
//  JobDetailFormatting.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · View — pure display formatters for the detail view.
//

import Foundation

/// Turns a possibly-HTML job description (Adzuna returns markup) into readable plain
/// text for display. Stripping happens **on display** (the domain `JobListing` keeps
/// the raw description) — a pure function so it's unit-tested without a view.
nonisolated enum HTMLStripper {
    static func plainText(_ html: String) -> String {
        var text = html
        // Turn line-breaking / block-closing tags into newlines before stripping.
        text = text.replacingOccurrences(of: "(?i)<br\\s*/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "(?i)</(p|div|li|h[1-6]|ul|ol)>", with: "\n", options: .regularExpression)
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

/// Formats an optional ``SalaryRange`` into a display string, or `nil` when there's
/// nothing to show. Pure, so it's unit-tested directly.
nonisolated enum SalaryFormatter {
    static func text(_ range: SalaryRange) -> String? {
        let prefix = range.currency.map { "\($0) " } ?? "$"
        func money(_ value: Double) -> String { prefix + Int(value).formatted() }

        switch (range.min, range.max) {
        case let (min?, max?): return min == max ? money(min) : "\(money(min)) – \(money(max))"
        case let (min?, nil):  return "\(money(min))+"
        case let (nil, max?):  return "Up to \(money(max))"
        case (nil, nil):       return nil
        }
    }
}
