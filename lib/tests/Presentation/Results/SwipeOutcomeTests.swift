//
//  SwipeOutcomeTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results — the pure swipe decision (Milestone V-C).
//

import Testing
import CoreGraphics
@testable import Taylor_d_Portfolio

@Suite("SwipeOutcome")
struct SwipeOutcomeTests {
    private let threshold: CGFloat = 120

    @Test func rightPastThresholdSaves() {
        #expect(SwipeOutcome.resolve(translation: 130, threshold: threshold) == .save)
        #expect(SwipeOutcome.resolve(translation: threshold, threshold: threshold) == .save)  // inclusive
    }

    @Test func leftPastThresholdDismisses() {
        #expect(SwipeOutcome.resolve(translation: -130, threshold: threshold) == .dismiss)
        #expect(SwipeOutcome.resolve(translation: -threshold, threshold: threshold) == .dismiss)
    }

    @Test func smallDragsDoNothing() {
        #expect(SwipeOutcome.resolve(translation: 40, threshold: threshold) == .none)
        #expect(SwipeOutcome.resolve(translation: -40, threshold: threshold) == .none)
        #expect(SwipeOutcome.resolve(translation: 0, threshold: threshold) == .none)
    }
}
