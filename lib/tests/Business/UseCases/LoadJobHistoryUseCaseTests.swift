//
//  LoadJobHistoryUseCaseTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business · UseCases — the seen/generated/applied join (Milestone S-C).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("LoadJobHistoryUseCase")
struct LoadJobHistoryUseCaseTests {

    private func ranked(_ id: String) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "t", company: "c", location: "l", description: "d"),
            match: JobMatch(jobId: id, score: 50, reason: "", matchedSkills: [], missingSkills: [])
        )
    }

    private func makeUseCase() -> (LoadJobHistoryUseCase, SavedJobsRepository, SavedStatusRepository, SavedApplicationsRepository) {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        return (LoadJobHistoryUseCase(jobs: jobs, statuses: statuses, applications: apps), jobs, statuses, apps)
    }

    @Test func emptyStoresYieldNoHistory() async throws {
        let (loadHistory, _, _, _) = makeUseCase()
        #expect(try await loadHistory().isEmpty)
    }

    @Test func joinsAllThreeSourcesByJobID() async throws {
        let (loadHistory, jobs, statuses, apps) = makeUseCase()
        try await jobs.save([ranked("seen"), ranked("applied"), ranked("generated")])
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 3)), forJobID: "applied")
        try await statuses.save(ApplicationStatus(stage: .saved), forJobID: "generated")
        try await apps.save(ApplicationKit(resumeMarkdown: "R", coverLetter: "C", gapNote: ""), forJobID: "generated")

        let history = try await loadHistory()

        #expect(history["seen"] == JobHistory(isSaved: true))
        #expect(history["applied"]?.status?.stage == .applied)
        #expect(history["applied"]?.isGenerated == false)
        #expect(history["generated"]?.isSaved == true)
        #expect(history["generated"]?.isGenerated == true)
        #expect(history["generated"]?.status?.stage == .saved)
    }

    @Test func includesIDsPresentInOnlyOneSource() async throws {
        // A status or kit whose listing is no longer saved still appears (union of ids).
        let (loadHistory, _, statuses, apps) = makeUseCase()
        try await statuses.save(ApplicationStatus(stage: .rejected, closedDate: Date(timeIntervalSince1970: 4)), forJobID: "status-only")
        try await apps.save(ApplicationKit(resumeMarkdown: "R", coverLetter: "", gapNote: ""), forJobID: "kit-only")

        let history = try await loadHistory()

        #expect(history["status-only"]?.isSaved == false)
        #expect(history["status-only"]?.status?.stage == .rejected)
        #expect(history["kit-only"]?.isGenerated == true)
        #expect(history["kit-only"]?.isSaved == false)
        #expect(history["kit-only"]?.status == nil)
    }
}
