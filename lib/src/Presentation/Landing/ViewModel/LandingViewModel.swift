//
//  LandingViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Landing · ViewModel
//

import Observation

/// Drives the Landing screen. Holds the "Get Started" intent; the composition root
/// supplies the action that routes into the main flow (Milestone I).
@MainActor
@Observable
final class LandingViewModel {
    private let onGetStarted: () -> Void

    init(onGetStarted: @escaping () -> Void = {}) {
        self.onGetStarted = onGetStarted
    }

    func getStarted() {
        onGetStarted()
    }
}
