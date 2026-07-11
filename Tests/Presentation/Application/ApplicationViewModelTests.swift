//
//  ApplicationViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Application
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// An `LLMProvider` that records how many times generation ran, so tests can assert a
/// saved kit is loaded *without* calling the engine.
private actor RecordingGenProvider: LLMProvider {
    private(set) var generateCalls = 0
    private(set) var lastGrounding: PortfolioGrounding?
    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        .init(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { [] }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        .init(company: "", roleTitle: "", mustHaveKeywords: [], niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        try await generateApplication(for: job, profile: profile, brief: brief, grounding: nil)
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?) async throws -> ApplicationKit {
        generateCalls += 1
        lastGrounding = grounding
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

    // MARK: T-B — generation grounding

    @Test func generateThreadsGroundingThroughToTheProvider() async {
        let provider = RecordingGenProvider()
        let vm = ApplicationViewModel(generateApplication: GenerateApplicationUseCase(provider: provider))
        let grounding = PortfolioGrounding(resumeText: "my real resume", coverLetterText: "my voice")
        await vm.generate(for: job, profile: profile, grounding: grounding)
        #expect(vm.kit?.resumeMarkdown == "FRESH")
        #expect(await provider.lastGrounding == grounding)   // résumé + cover letter reach the engine
    }

    @Test func openWithoutGroundingFallsBackToProfileOnly() async {
        let provider = RecordingGenProvider()
        let vm = ApplicationViewModel(generateApplication: GenerateApplicationUseCase(provider: provider))
        await vm.open(for: job, profile: profile)            // no grounding passed
        #expect(await provider.lastGrounding == nil)         // back-compat: profile-only
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

    // MARK: Milestone X — templates + one-page gate

    /// A `DocumentExporter` whose page count is scripted per template, so the gate is testable
    /// without real Core Text pagination. Also records the template it was asked to export with.
    private final class ScriptedExporter: DocumentExporter, @unchecked Sendable {
        var pagesByTemplate: [ExportTemplate: Int]
        private(set) var lastExportTemplate: ExportTemplate?
        init(pagesByTemplate: [ExportTemplate: Int]) { self.pagesByTemplate = pagesByTemplate }
        func export(markdown: String, as format: ExportFormat, template: ExportTemplate) throws -> Data {
            lastExportTemplate = template
            return Data(markdown.utf8)
        }
        func pageCount(markdown: String, template: ExportTemplate) throws -> Int {
            pagesByTemplate[template] ?? 1
        }
    }

    private func gateVM(_ exporter: ScriptedExporter) -> ApplicationViewModel {
        ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(kitResume: "# Resume\nSwift dev")),
            exportApplication: ExportApplicationUseCase(exporter: exporter)
        )
    }

    @Test func onePageGateFlagsALongResume() async {
        let vm = gateVM(ScriptedExporter(pagesByTemplate: [.classic: 2]))
        await vm.generate(for: job, profile: profile)
        #expect(vm.resumePageCount == 2)
        #expect(vm.resumeExceedsOnePage)
    }

    @Test func onePageGateStaysQuietForAOnePageResume() async {
        let vm = gateVM(ScriptedExporter(pagesByTemplate: [.classic: 1]))
        await vm.generate(for: job, profile: profile)
        #expect(vm.resumePageCount == 1)
        #expect(vm.resumeExceedsOnePage == false)
    }

    @Test func switchingTemplateRemeasuresTheGate() async {
        let vm = gateVM(ScriptedExporter(pagesByTemplate: [.classic: 2, .compact: 1]))
        await vm.generate(for: job, profile: profile)
        #expect(vm.resumeExceedsOnePage)          // 2 pages in Classic

        vm.exportTemplate = .compact
        vm.refreshLengthGate()
        #expect(vm.resumePageCount == 1)          // Compact fits it
        #expect(vm.resumeExceedsOnePage == false)
    }

    @Test func exportUsesTheSelectedTemplate() async {
        let exporter = ScriptedExporter(pagesByTemplate: [:])
        let vm = gateVM(exporter)
        await vm.generate(for: job, profile: profile)
        vm.exportTemplate = .modern
        _ = vm.exportData(.pdf)
        #expect(exporter.lastExportTemplate == .modern)
    }
}
