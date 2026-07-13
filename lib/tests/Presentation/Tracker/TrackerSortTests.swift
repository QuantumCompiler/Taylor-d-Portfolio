//
//  TrackerSortTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Tracker — the pure TrackerSort value (Milestone H).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("TrackerSort")
struct TrackerSortTests {

    /// A tracked job with a given id, title, company, score, and status.
    private func tracked(_ id: String, title: String = "Engineer", company: String = "Co",
                         score: Int = 50, status: ApplicationStatus) -> TrackedJob {
        TrackedJob(
            job: RankedJob(
                listing: JobListing(id: id, title: title, company: company, location: "l", description: "d"),
                match: JobMatch(jobId: id, score: score, reason: "", matchedSkills: [], missingSkills: [])
            ),
            status: status
        )
    }

    private func date(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }

    // MARK: Default

    @Test func defaultSortsMostRecentActivityFirstUndatedLast() {
        let jobs = [
            tracked("old", status: ApplicationStatus(stage: .applied, appliedDate: date(100))),
            tracked("new", status: ApplicationStatus(stage: .offer, offerDate: date(900))),
            tracked("none", title: "Aardvark", status: ApplicationStatus(stage: .saved)),   // no date
        ]
        let ordered = TrackerSort.default.apply(to: jobs).map(\.id)
        #expect(ordered == ["new", "old", "none"])   // dated desc, undated always last
        #expect(TrackerSort.default.isDefault)
    }

    // MARK: Direction

    @Test func ascendingActivityReversesDatedButKeepsUndatedLast() {
        let jobs = [
            tracked("old", status: ApplicationStatus(stage: .applied, appliedDate: date(100))),
            tracked("new", status: ApplicationStatus(stage: .offer, offerDate: date(900))),
            tracked("none", status: ApplicationStatus(stage: .saved)),
        ]
        var sort = TrackerSort(key: .recentActivity, direction: .ascending)
        #expect(sort.apply(to: jobs).map(\.id) == ["old", "new", "none"])   // undated still last
        #expect(sort.isDefault == false)
        sort.direction = .descending
        #expect(sort.apply(to: jobs).map(\.id) == ["new", "old", "none"])
    }

    // MARK: Keys

    @Test func sortsByMatchScore() {
        let jobs = [
            tracked("lo", score: 20, status: ApplicationStatus(stage: .saved)),
            tracked("hi", score: 90, status: ApplicationStatus(stage: .saved)),
            tracked("mid", score: 55, status: ApplicationStatus(stage: .saved)),
        ]
        #expect(TrackerSort(key: .matchScore, direction: .descending).apply(to: jobs).map(\.id) == ["hi", "mid", "lo"])
        #expect(TrackerSort(key: .matchScore, direction: .ascending).apply(to: jobs).map(\.id) == ["lo", "mid", "hi"])
    }

    @Test func sortsByStageProgression() {
        let jobs = [
            tracked("offer", status: ApplicationStatus(stage: .offer)),
            tracked("saved", status: ApplicationStatus(stage: .saved)),
            tracked("applied", status: ApplicationStatus(stage: .applied)),
        ]
        // Ascending = progression order Saved → Applied → Offer.
        #expect(TrackerSort(key: .stage, direction: .ascending).apply(to: jobs).map(\.id) == ["saved", "applied", "offer"])
        #expect(TrackerSort(key: .stage, direction: .descending).apply(to: jobs).map(\.id) == ["offer", "applied", "saved"])
    }

    @Test func sortsByCompanyAndTitleCaseInsensitively() {
        let jobs = [
            tracked("b", title: "iOS Engineer", company: "banana", status: ApplicationStatus(stage: .saved)),
            tracked("a", title: "Backend Engineer", company: "Apple", status: ApplicationStatus(stage: .saved)),
            tracked("c", title: "Android Engineer", company: "cherry", status: ApplicationStatus(stage: .saved)),
        ]
        #expect(TrackerSort(key: .company, direction: .ascending).apply(to: jobs).map(\.id) == ["a", "b", "c"])
        #expect(TrackerSort(key: .title, direction: .ascending).apply(to: jobs).map(\.id) == ["c", "a", "b"])
    }

    // MARK: Stability

    @Test func equalKeysBreakTiesOnTitle() {
        let jobs = [
            tracked("z", title: "Zebra", score: 50, status: ApplicationStatus(stage: .saved)),
            tracked("a", title: "Alpha", score: 50, status: ApplicationStatus(stage: .saved)),
        ]
        // Same score → tie-break on title ascending, regardless of input order/direction.
        #expect(TrackerSort(key: .matchScore, direction: .descending).apply(to: jobs).map(\.id) == ["a", "z"])
    }

    @Test func dateAppliedIgnoresOtherMilestones() {
        let jobs = [
            tracked("late", status: ApplicationStatus(stage: .offer, appliedDate: date(500), offerDate: date(999))),
            tracked("early", status: ApplicationStatus(stage: .interviewing, appliedDate: date(200), interviewDate: date(800))),
        ]
        // Ordered by appliedDate specifically (descending), not the current-stage date.
        #expect(TrackerSort(key: .dateApplied, direction: .descending).apply(to: jobs).map(\.id) == ["late", "early"])
    }
}
