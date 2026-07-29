//
//  SavedApplicationsRepositoryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — ApplicationKit ↔ store mapping, keyed by job id.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("SavedApplicationsRepository")
struct SavedApplicationsRepositoryTests {

    private func kit(_ resume: String) -> ApplicationKit {
        ApplicationKit(resumeMarkdown: resume, coverLetter: "## About Me", gapNote: "none")
    }

    private func brief(_ role: String) -> TargetBrief {
        TargetBrief(company: "Acme", roleTitle: role, mustHaveKeywords: ["Swift"],
                    niceToHaveKeywords: [], techStack: ["Xcode"], domain: "Mobile", missionValues: "")
    }

    @Test func saveThenLoadByJobIDRoundTrips() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(kit("# Resume A"), forJobID: "job-a")

        #expect(try await repo.kit(forJobID: "job-a") == kit("# Resume A"))
        #expect(try await repo.kit(forJobID: "job-b") == nil)   // unknown job
    }

    @Test func saveLatestWinsPerJob() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(kit("first"), forJobID: "job-a")
        try await repo.save(kit("second"), forJobID: "job-a")
        #expect(try await repo.kit(forJobID: "job-a")?.resumeMarkdown == "second")
    }

    @Test func kitsAreKeyedIndependentlyPerJob() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(kit("A"), forJobID: "job-a")
        try await repo.save(kit("B"), forJobID: "job-b")
        #expect(try await repo.kit(forJobID: "job-a")?.resumeMarkdown == "A")
        #expect(try await repo.kit(forJobID: "job-b")?.resumeMarkdown == "B")
    }

    // MARK: v0.6.1 Milestone B — the brief rides in the kit's own record

    @Test func briefRoundTripsAlongsideTheKit() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(kit("# Resume"), brief: brief("iOS Engineer"), forJobID: "job-a")

        #expect(try await repo.kit(forJobID: "job-a") == kit("# Resume"))
        #expect(try await repo.brief(forJobID: "job-a") == brief("iOS Engineer"))
        #expect(try await repo.brief(forJobID: "job-b") == nil)   // unknown job
    }

    @Test func savingWithoutABriefStillStoresTheKit() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(kit("# Resume"), forJobID: "job-a")
        #expect(try await repo.kit(forJobID: "job-a")?.resumeMarkdown == "# Resume")
        #expect(try await repo.brief(forJobID: "job-a") == nil)
    }

    @Test func latestSaveReplacesTheBriefToo() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(kit("first"), brief: brief("iOS Engineer"), forJobID: "job-a")
        try await repo.save(kit("second"), brief: brief("Staff Engineer"), forJobID: "job-a")
        // The pair moves together — a stale brief can never outlive the résumé it described.
        #expect(try await repo.kit(forJobID: "job-a")?.resumeMarkdown == "second")
        #expect(try await repo.brief(forJobID: "job-a")?.roleTitle == "Staff Engineer")
    }

    @Test func legacyBareKitRecordsStillLoad() async throws {
        // A record written before the brief was paired in: a bare `ApplicationKit` blob.
        let store = InMemoryRecordStore()
        let legacy = try JSONEncoder().encode(kit("# Legacy"))
        try await store.upsert(kind: SavedApplicationsRepository.kind, id: "job-a", data: legacy)

        let repo = SavedApplicationsRepository(store: store)
        #expect(try await repo.kit(forJobID: "job-a") == kit("# Legacy"))
        #expect(try await repo.brief(forJobID: "job-a") == nil)   // coverage is unavailable, not wrong
    }
}
