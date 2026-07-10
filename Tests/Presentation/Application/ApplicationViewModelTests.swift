//
//  ApplicationViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Application
//

import Testing
@testable import Taylor_d_Portfolio

/// An `LLMProvider` that records how many times generation ran, so tests can assert a
/// saved kit is loaded *without* calling the engine.
private actor RecordingGenProvider: LLMProvider {
    private(set) var generateCalls = 0
    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        .init(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { [] }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        .init(company: "", roleTitle: "", mustHaveKeywords: [], niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        generateCalls += 1
        return ApplicationKit(resumeMarkdown: "FRESH", coverLetter: "", gapNote: "")
    }
}

@MainActor
@Suite("ApplicationViewModel")
struct ApplicationViewModelTests {

    private let job = JobListing(id: "a", title: "t", company: "c", location: "l", description: "d")
    private var profile: CandidateProfile {
        CandidateProfile(seniority: "S", yearsExperience: 1, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }

    private func savedKit(_ resume: String) -> ApplicationKit {
        ApplicationKit(resumeMarkdown: resume, coverLetter: "", gapNote: "")
    }

    @Test func generateSetsKitOnSuccess() async {
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(kitResume: "RESUME"))
        )
        await vm.generate(for: job, profile: profile)
        #expect(vm.kit?.resumeMarkdown == "RESUME")
        #expect(vm.errorMessage == nil)
        #expect(vm.isGenerating == false)
    }

    @Test func generateSetsErrorOnFailure() async {
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(shouldThrow: true))
        )
        await vm.generate(for: job, profile: profile)
        #expect(vm.kit == nil)
        #expect(vm.errorMessage != nil)
        #expect(vm.isGenerating == false)
    }

    // MARK: O-C — persistence

    @Test func openGeneratesAndPersistsWhenNothingSaved() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        let provider = RecordingGenProvider()
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: provider),
            saveApplication: SaveApplicationUseCase(repository: repo),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )
        await vm.open(for: job, profile: profile)

        #expect(vm.kit?.resumeMarkdown == "FRESH")
        #expect(vm.isSaved == false)
        #expect(await provider.generateCalls == 1)
        #expect(try await repo.kit(forJobID: job.id)?.resumeMarkdown == "FRESH")   // persisted
    }

    @Test func openLoadsSavedKitWithoutCallingProvider() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(savedKit("# Saved"), forJobID: job.id)
        let provider = RecordingGenProvider()
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: provider),
            saveApplication: SaveApplicationUseCase(repository: repo),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )
        await vm.open(for: job, profile: profile)

        #expect(vm.kit?.resumeMarkdown == "# Saved")
        #expect(vm.isSaved)
        #expect(await provider.generateCalls == 0)   // no redundant generation
    }

    @Test func regenerateForcesFreshOutputEvenWhenSaved() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(savedKit("# Saved"), forJobID: job.id)
        let provider = RecordingGenProvider()
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: provider),
            saveApplication: SaveApplicationUseCase(repository: repo),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )
        await vm.generate(for: job, profile: profile)   // "Regenerate"

        #expect(vm.kit?.resumeMarkdown == "FRESH")
        #expect(vm.isSaved == false)
        #expect(await provider.generateCalls == 1)
        #expect(try await repo.kit(forJobID: job.id)?.resumeMarkdown == "FRESH")   // latest-wins persisted
    }

    // MARK: Q-A — export

    private func exportVM() -> ApplicationViewModel {
        ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(kitResume: "# Resume\nSwift dev")),
            exportApplication: ExportApplicationUseCase(exporter: MarkdownDocumentExporter())
        )
    }

    @Test func cannotExportBeforeAKitExists() {
        let vm = exportVM()
        #expect(vm.canExport == false)
        #expect(vm.exportData(.markdown) == nil)
        #expect(vm.exportedText() == nil)
    }

    @Test func exportsMarkdownAndPlainTextOnceGenerated() async {
        let vm = exportVM()
        await vm.generate(for: job, profile: profile)

        #expect(vm.canExport)
        let markdown = vm.exportedText(.markdown)
        #expect(markdown?.contains("# Résumé") == true)
        #expect(markdown?.contains("Swift dev") == true)

        let plain = vm.exportedText(.plainText)
        #expect(plain?.contains("#") == false)
        #expect(plain?.contains("Swift dev") == true)

        #expect(vm.exportData(.pdf) == nil)   // unsupported format degrades to nil, no crash
    }

    @Test func exportWithoutAnExporterIsUnavailable() async {
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(kitResume: "R"))
        )
        await vm.generate(for: job, profile: profile)
        #expect(vm.kit != nil)
        #expect(vm.canExport == false)        // no exporter wired
        #expect(vm.exportData(.markdown) == nil)
    }

    @Test func filenameBaseComesFromTheJob() async {
        let vm = exportVM()
        await vm.generate(for: JobListing(id: "x", title: "iOS Engineer", company: "Acme/Co", location: "l", description: "d"),
                          profile: profile)
        // Company · role, with filesystem-illegal characters replaced.
        #expect(vm.exportFilenameBase == "Acme-Co - iOS Engineer")
    }

    @Test func filenameBaseFallsBackWhenNoJob() {
        #expect(exportVM().exportFilenameBase == "Application")
    }
}
