//
//  SwipeOutcome.swift
//  Taylor'd Portfolio
//
//  Presentation · Results — the pure decision for a swipeable result card (Milestone V-C).
//

import Foundation

/// What a horizontal swipe on the Results card resolves to. Pure and unit-testable; the
/// gesture wiring + animation live in the view and are a manual-feel check.
enum SwipeOutcome: Equatable {
    /// Dragged right past the threshold → save to the Tracker, then dismiss.
    case save
    /// Dragged left past the threshold → dismiss without saving or deleting.
    case dismiss
    /// A small drag → snap back, no action.
    case none

    /// Resolves a horizontal `translation` against a positive `threshold`.
    static func resolve(translation: CGFloat, threshold: CGFloat) -> SwipeOutcome {
        if translation >= threshold { return .save }
        if translation <= -threshold { return .dismiss }
        return .none
    }
}
