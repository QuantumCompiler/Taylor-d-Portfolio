//
//  AppSessionTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · App — the shared window session (v0.5.0 Milestone B-A).
//

import Testing
@testable import Taylor_d_Portfolio

@MainActor
@Suite("AppSession")
struct AppSessionTests {
    @Test func dataChangedBumpsRevisionMonotonically() {
        let session = AppSession()
        #expect(session.revision == 0)
        session.dataChanged()
        #expect(session.revision == 1)
        session.dataChanged()
        #expect(session.revision == 2)
    }

    @Test func showDetailTargetsJobAndContext() {
        let session = AppSession()
        let job = Preview.sampleRankedJobs[0]

        session.showDetail(job, context: .results)
        #expect(session.detailJob == job)
        #expect(session.detailContext == .results)

        let other = Preview.sampleRankedJobs[1]
        session.showDetail(other, context: .tracker)
        #expect(session.detailJob == other)
        #expect(session.detailContext == .tracker)
    }
}
