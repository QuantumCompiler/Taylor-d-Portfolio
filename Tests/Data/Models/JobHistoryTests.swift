//
//  JobHistoryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Models — the cross-screen history badge assembly (Milestone S-C).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("JobHistory")
struct JobHistoryTests {

    @Test func brandNewHasNoFacetsOrHistory() {
        let history = JobHistory()
        #expect(history.facets.isEmpty)
        #expect(history.hasHistory == false)
        #expect(history.isTracked == false)
    }

    @Test func savedButUntrackedShowsSeenOnly() {
        let history = JobHistory(isSaved: true)
        #expect(history.facets == [.seen])
        #expect(history.hasHistory)
        #expect(history.isTracked == false)
    }

    @Test func statusSubsumesSeen() {
        // A tracked job is obviously saved — show the status, not a redundant "Seen".
        let status = ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 1))
        let history = JobHistory(isSaved: true, status: status)
        #expect(history.facets == [.status(status)])
        #expect(history.isTracked)
    }

    @Test func generatedIsAlwaysItsOwnTrailingFacet() {
        let seenGenerated = JobHistory(isSaved: true, isGenerated: true)
        #expect(seenGenerated.facets == [.seen, .generated])

        let status = ApplicationStatus(stage: .interviewing, interviewDate: Date(timeIntervalSince1970: 2))
        let trackedGenerated = JobHistory(isSaved: true, isGenerated: true, status: status)
        #expect(trackedGenerated.facets == [.status(status), .generated])
    }

    @Test func generatedWithoutSaveStillSurfaces() {
        // Defensive: a kit without a saved listing still reads as generated.
        let history = JobHistory(isGenerated: true)
        #expect(history.facets == [.generated])
        #expect(history.hasHistory)
    }
}
