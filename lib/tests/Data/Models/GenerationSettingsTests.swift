//
//  GenerationSettingsTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Models — generation controls (v0.5.0 Milestone D).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("GenerationSettings")
struct GenerationSettingsTests {
    @Test func defaultIsGroundedAndFlaggedDefault() {
        let s = GenerationSettings.default
        #expect(s.fidelity == 0)
        #expect(s.aspects.isEmpty)
        #expect(s.desiredRankMatch == nil)
        #expect(s.isDefault)
        #expect(s.band == .authentic)
        #expect(s.mayEmbellish == false)
    }

    @Test func bandThresholds() {
        #expect(GenerationSettings(fidelity: 0.0).band == .authentic)
        #expect(GenerationSettings(fidelity: 0.14).band == .authentic)
        #expect(GenerationSettings(fidelity: 0.15).band == .curated)
        #expect(GenerationSettings(fidelity: 0.5).band == .curated)
        #expect(GenerationSettings(fidelity: 0.74).band == .curated)
        #expect(GenerationSettings(fidelity: 0.75).band == .embellished)
        #expect(GenerationSettings(fidelity: 1.0).band == .embellished)
        #expect(GenerationSettings(fidelity: 1.0).mayEmbellish)
    }

    @Test func nonDefaultWhenAnyControlSet() {
        #expect(GenerationSettings(fidelity: 0.2).isDefault == false)
        #expect(GenerationSettings(aspects: [.summary]).isDefault == false)
        #expect(GenerationSettings(desiredRankMatch: 80).isDefault == false)
    }

    @Test func codableRoundTrip() throws {
        let s = GenerationSettings(fidelity: 0.6, aspects: [.summary, .skills], desiredRankMatch: 85)
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(GenerationSettings.self, from: data)
        #expect(back == s)
    }

    // MARK: Milestone I — free-text additional context

    @Test func additionalContextCountsAgainstDefaultButNotControls() {
        let s = GenerationSettings(additionalContext: "focus on leadership")
        #expect(s.isDefault == false)      // non-empty context ⇒ not the byte-for-byte grounded default
        #expect(s.hasDefaultControls)      // …but the fidelity/aspect/target controls are still default
        #expect(GenerationSettings().hasDefaultControls)
        #expect(GenerationSettings(fidelity: 0.5).hasDefaultControls == false)
        #expect(GenerationSettings(desiredRankMatch: 80).hasDefaultControls == false)
    }

    @Test func additionalContextIsNotPersisted() throws {
        // Excluded from Codable so it never lands in a saved preset; decodes back to "".
        let s = GenerationSettings(fidelity: 0.5, additionalContext: "per-job note")
        let back = try JSONDecoder().decode(GenerationSettings.self, from: try JSONEncoder().encode(s))
        #expect(back.additionalContext == "")   // context dropped on encode
        #expect(back.fidelity == 0.5)            // the real controls still round-trip
        #expect(back != s)                       // and the context difference shows in Equatable
    }
}
