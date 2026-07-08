//
//  LandingViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Landing
//

import Testing
@testable import Taylor_d_Portfolio

@MainActor
@Suite("LandingViewModel")
struct LandingViewModelTests {

    @Test func getStartedInvokesTheInjectedAction() {
        var called = false
        let vm = LandingViewModel(onGetStarted: { called = true })
        vm.getStarted()
        #expect(called)
    }
}
