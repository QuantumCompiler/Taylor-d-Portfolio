//
//  SavedApplicationsRepositoryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — ApplicationKit ↔ store mapping, keyed by job id.
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("SavedApplicationsRepository")
struct SavedApplicationsRepositoryTests {

    private func kit(_ resume: String) -> ApplicationKit {
        ApplicationKit(resumeMarkdown: resume, coverLetter: "## About Me", gapNote: "none")
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
}
