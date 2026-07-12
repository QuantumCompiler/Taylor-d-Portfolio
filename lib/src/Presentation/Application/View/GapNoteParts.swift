//
//  GapNoteParts.swift
//  Taylor'd Portfolio
//
//  Presentation · Application — split a kit's gapNote into disclosures + honest gaps (D-E).
//

import Foundation

/// Splits a generated kit's `gapNote` into two parts (Milestone D-E):
/// - `embellishments`: content the model disclosed as NOT supported by the real profile
///   (lines it prefixed "EMBELLISHED:" when generating in the embellished band).
/// - `gaps`: the remaining honest gap note (must-haves the candidate doesn't meet).
///
/// Pure, so it's unit-testable without the SwiftUI view.
nonisolated struct GapNoteParts: Equatable {
    let embellishments: [String]
    let gaps: String

    var hasEmbellishments: Bool { !embellishments.isEmpty }

    static func parse(_ gapNote: String) -> GapNoteParts {
        var embellishments: [String] = []
        var gapLines: [String] = []
        for rawLine in gapNote.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Match the disclosure marker anywhere on the line (may be bulleted, e.g. "- EMBELLISHED: …").
            if let marker = trimmed.range(of: "EMBELLISHED:") {
                let detail = trimmed[marker.upperBound...].trimmingCharacters(in: .whitespaces)
                if !detail.isEmpty { embellishments.append(detail) }
            } else {
                gapLines.append(line)
            }
        }
        let gaps = gapLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return GapNoteParts(embellishments: embellishments, gaps: gaps)
    }
}
