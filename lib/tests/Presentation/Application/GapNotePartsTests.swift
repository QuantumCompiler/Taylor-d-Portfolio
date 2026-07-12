//
//  GapNotePartsTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Application — disclosure parsing (Milestone D-E).
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("GapNoteParts")
struct GapNotePartsTests {
    @Test func noEmbellishmentsKeepsGapsIntact() {
        let parts = GapNoteParts.parse("Missing: 5 years of Rust.\nMissing: PhD.")
        #expect(parts.hasEmbellishments == false)
        #expect(parts.embellishments.isEmpty)
        #expect(parts.gaps == "Missing: 5 years of Rust.\nMissing: PhD.")
    }

    @Test func extractsEmbellishedLinesAndLeavesTheGaps() {
        let note = """
        EMBELLISHED: Added a claim of leading a team of 10.
        - EMBELLISHED: Inflated years of Swift from 5 to 8.
        Missing: no Kubernetes experience.
        """
        let parts = GapNoteParts.parse(note)
        #expect(parts.hasEmbellishments)
        #expect(parts.embellishments == [
            "Added a claim of leading a team of 10.",
            "Inflated years of Swift from 5 to 8.",
        ])
        #expect(parts.gaps == "Missing: no Kubernetes experience.")
    }

    @Test func emptyGapNoteHasNeither() {
        let parts = GapNoteParts.parse("")
        #expect(parts.hasEmbellishments == false)
        #expect(parts.gaps.isEmpty)
    }
}
