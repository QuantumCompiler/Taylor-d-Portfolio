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

/// A provider whose brief carries real keywords and whose résumé covers only some of them, so
/// keyword coverage can be exercised end to end through the view model (v0.6.1 Milestone C).
private actor CoverageStubProvider: LLMProvider {
    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        .init(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { [] }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        .init(company: "Acme", roleTitle: "iOS Engineer", mustHaveKeywords: ["Swift", "Kotlin"],
              niceToHaveKeywords: ["Metal"], techStack: [], domain: "", missionValues: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        // Markdown on purpose: coverage must read the *visible* text, past the syntax.
        ApplicationKit(resumeMarkdown: "# Resume\n- **Swift** and Metal", coverLetter: "", gapNote: "")
    }
}

/// An `LLMProvider` whose generation **blocks until the test releases it** — the stale-async
/// tests (v0.7.1 Milestone A) need a run for job A still in flight while the window re-targets
/// to job B. Deliberately ignores cancellation: the run-token guard must hold even when the
/// underlying LLM call doesn't honour `Task.cancel()`.
private actor GatedGenProvider: LLMProvider {
    var shouldThrow = false
    private var waiting: [CheckedContinuation<Void, Never>] = []
    private(set) var pendingCount = 0

    struct Boom: Error {}

    func setShouldThrow(_ value: Bool) { shouldThrow = value }

    /// Lets every blocked generation proceed.
    func release() {
        let continuations = waiting
        waiting = []
        for continuation in continuations { continuation.resume() }
    }

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        .init(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { [] }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        .init(company: job.company, roleTitle: job.title, mustHaveKeywords: [],
              niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        pendingCount += 1
        await withCheckedContinuation { waiting.append($0) }
        pendingCount -= 1
        if shouldThrow { throw Boom() }
        // The kit names its job, so a test can tell whose output landed on screen.
        return ApplicationKit(resumeMarkdown: "KIT-\(job.id)", coverLetter: "", gapNote: "")
    }
}

/// A `LaTeXCompiling` stub for the awesome-cv export path (Milestone D).
private final class VMStubCompiler: LaTeXCompiling, @unchecked Sendable {
    let available: Bool
    let result: Result<Data, Error>
    /// The last `.tex` compiled — how the style tests prove the picker's choice reached here.
    private(set) var lastTex: String?
    init(available: Bool = true, result: Result<Data, Error> = .success(Data("%PDF".utf8))) {
        self.available = available
        self.result = result
    }
    var isAvailable: Bool { available }
    func compile(tex: String, jobName: String) async throws -> Data {
        lastTex = tex
        return try result.get()
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

    @Test func loadSavedNeverAutoGeneratesThenExplicitGeneratePersists() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        let provider = RecordingGenProvider()
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: provider),
            saveApplication: SaveApplicationUseCase(repository: repo),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )
        await vm.loadSaved(for: job)
        #expect(vm.kit == nil)                        // opening never auto-generates (v0.5.0)
        #expect(await provider.generateCalls == 0)

        await vm.generate(for: job, profile: profile)  // the explicit Generate button
        #expect(vm.kit?.resumeMarkdown == "FRESH")
        #expect(await provider.generateCalls == 1)
        #expect(try await repo.kit(forJobID: job.id)?.resumeMarkdown == "FRESH")   // persisted
    }

    @Test func loadSavedShowsSavedKitWithoutCallingProvider() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(savedKit("# Saved"), forJobID: job.id)
        let provider = RecordingGenProvider()
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: provider),
            saveApplication: SaveApplicationUseCase(repository: repo),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )
        await vm.loadSaved(for: job)

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

    // MARK: v0.7.1 Milestone A — stale-async generation can't corrupt the shown job

    /// Spins until the provider has `count` generations blocked (bounded, so a regression
    /// fails the test instead of hanging it).
    private func waitForPending(_ provider: GatedGenProvider, count: Int = 1) async {
        var spins = 0
        while await provider.pendingCount < count, spins < 10_000 {
            spins += 1
            await Task.yield()
        }
        #expect(await provider.pendingCount >= count)
    }

    /// The core defect: generate for job A, re-target the window to job B while A is still in
    /// flight — A finishing late must not put its kit under B's header (an export named for B
    /// containing A's résumé). A's output is still **persisted under A's id**: the generation
    /// was paid for, and persistence was never the corrupt path.
    @Test func aStaleGenerationCannotOverwriteTheRetargetedJob() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        let jobB = JobListing(id: "b", title: "tb", company: "cb", location: "l", description: "d")
        try await repo.save(savedKit("# Saved-B"), forJobID: jobB.id)
        let provider = GatedGenProvider()
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: provider),
            saveApplication: SaveApplicationUseCase(repository: repo),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )

        let generation = Task { await vm.generate(for: job, profile: profile) }   // job "a"
        await waitForPending(provider)
        #expect(vm.isGenerating)

        await vm.loadSaved(for: jobB)                     // the user opens job B mid-flight
        #expect(vm.kit?.resumeMarkdown == "# Saved-B")
        #expect(vm.isGenerating == false)                 // Generate usable for B immediately

        await provider.release()                          // job A's run finishes late
        await generation.value

        #expect(vm.job?.id == "b")
        #expect(vm.kit?.resumeMarkdown == "# Saved-B")    // B's screen state survives
        #expect(vm.isGenerating == false)
        #expect(try await repo.kit(forJobID: "a")?.resumeMarkdown == "KIT-a")   // A's output kept
        #expect(try await repo.kit(forJobID: "b")?.resumeMarkdown == "# Saved-B")
    }

    /// Re-target to B and generate for B while A is still in flight: the **last targeted job
    /// wins**, no matter which run finishes last.
    @Test func theLastTargetedJobWinsWhenAnOlderRunFinishesLast() async throws {
        let jobB = JobListing(id: "b", title: "tb", company: "cb", location: "l", description: "d")
        let provider = GatedGenProvider()
        let vm = ApplicationViewModel(generateApplication: GenerateApplicationUseCase(provider: provider))

        let generationA = Task { await vm.generate(for: job, profile: profile) }
        await waitForPending(provider)
        await vm.loadSaved(for: jobB)
        let generationB = Task { await vm.generate(for: jobB, profile: profile) }
        await waitForPending(provider, count: 2)

        await provider.release()
        await generationA.value
        await generationB.value

        #expect(vm.kit?.resumeMarkdown == "KIT-b")
        #expect(vm.job?.id == "b")
        #expect(vm.isGenerating == false)
    }

    /// A superseded run's failure isn't news about the job now shown — no error banner.
    @Test func aSupersededRunsFailureIsNotSurfaced() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        let jobB = JobListing(id: "b", title: "tb", company: "cb", location: "l", description: "d")
        try await repo.save(savedKit("# Saved-B"), forJobID: jobB.id)
        let provider = GatedGenProvider()
        await provider.setShouldThrow(true)
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: provider),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )

        let generation = Task { await vm.generate(for: job, profile: profile) }
        await waitForPending(provider)
        await vm.loadSaved(for: jobB)

        await provider.release()                          // A's run now throws
        await generation.value

        #expect(vm.errorMessage == nil)                   // the failure died with the old run
        #expect(vm.kit?.resumeMarkdown == "# Saved-B")
        #expect(vm.isGenerating == false)
    }

    // MARK: v0.6.1 Milestone B — the brief travels with the kit

    private func savedBrief(_ role: String = "t") -> TargetBrief {
        TargetBrief(company: "c", roleTitle: role, mustHaveKeywords: ["Swift"],
                    niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }

    @Test func generateExposesTheBriefAndPersistsItWithTheKit() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(kitResume: "RESUME")),
            saveApplication: SaveApplicationUseCase(repository: repo)
        )
        await vm.generate(for: job, profile: profile)

        #expect(vm.brief?.roleTitle == "t")   // the stub briefs from the job's title
        #expect(try await repo.brief(forJobID: job.id)?.roleTitle == "t")
    }

    @Test func reopeningASavedResultRestoresItsBrief() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(savedKit("# Saved"), brief: savedBrief(), forJobID: job.id)
        let provider = RecordingGenProvider()
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: provider),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )
        await vm.loadSaved(for: job)

        #expect(vm.kit?.resumeMarkdown == "# Saved")
        #expect(vm.brief?.mustHaveKeywords == ["Swift"])
        #expect(await provider.generateCalls == 0)   // still no redundant generation
    }

    @Test func reopeningALegacySavedKitLeavesTheBriefNil() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(savedKit("# Saved"), forJobID: job.id)   // no brief stored
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: RecordingGenProvider()),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )
        await vm.loadSaved(for: job)

        #expect(vm.kit?.resumeMarkdown == "# Saved")   // the kit still loads
        #expect(vm.brief == nil)                       // coverage is simply unavailable
    }

    @Test func aFailedGenerationClearsTheBriefAlongWithTheKit() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(savedKit("# Saved"), brief: savedBrief(), forJobID: job.id)
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(shouldThrow: true)),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )
        await vm.loadSaved(for: job)
        #expect(vm.brief != nil)

        await vm.generate(for: job, profile: profile)   // "Regenerate", which fails
        #expect(vm.kit == nil)
        #expect(vm.brief == nil)                        // no stale brief left behind
        #expect(vm.errorMessage != nil)
    }

    // MARK: v0.6.1 Milestone C — keyword coverage

    @Test func coverageIsNilBeforeAnythingIsGenerated() async {
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: CoverageStubProvider())
        )
        #expect(vm.coverage == nil)
    }

    @Test func coverageReportsCoveredAndMissingAfterGenerate() async {
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: CoverageStubProvider())
        )
        await vm.generate(for: job, profile: profile)

        let coverage = vm.coverage
        #expect(coverage?.coveredCount == 1)          // "Swift" — the headline is must-haves
        #expect(coverage?.totalCount == 2)
        #expect(coverage?.mustHave?.covered == ["Swift"])
        #expect(coverage?.mustHave?.missing == ["Kotlin"])
        // The nice-to-have tier is still reported in the breakdown, just not in the headline.
        #expect(coverage?.allCoveredCount == 2)
        #expect(coverage?.tiers.count == 2)
    }

    @Test func coverageIsNilWhenThePostingYieldedNoKeywords() async {
        // The stub's brief has empty keyword tiers — a thin posting. Nothing honest to report.
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(kitResume: "# Resume"))
        )
        await vm.generate(for: job, profile: profile)

        #expect(vm.kit != nil)
        #expect(vm.brief != nil)
        #expect(vm.coverage == nil)   // the panel hides rather than showing "0/0 covered"
    }

    @Test func coverageIsNilForASavedRecordWithNoBrief() async throws {
        let repo = SavedApplicationsRepository(store: InMemoryRecordStore())
        try await repo.save(savedKit("# Resume\nSwift"), forJobID: job.id)   // legacy: no brief
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: CoverageStubProvider()),
            loadApplication: LoadApplicationUseCase(repository: repo)
        )
        await vm.loadSaved(for: job)

        #expect(vm.kit != nil)        // the documents still show
        #expect(vm.coverage == nil)   // coverage is unavailable, not wrong
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

    @Test func generateWithoutGroundingFallsBackToProfileOnly() async {
        let provider = RecordingGenProvider()
        let vm = ApplicationViewModel(generateApplication: GenerateApplicationUseCase(provider: provider))
        await vm.generate(for: job, profile: profile)        // no grounding passed
        #expect(await provider.lastGrounding == nil)         // back-compat: profile-only
    }

    // MARK: v0.6.0 Milestone B — profile selection at generation time

    private func savedProfile(id: String, name: String, resume: String, cover: String = "") -> SavedProfile {
        SavedProfile(
            id: id, name: name,
            profile: CandidateProfile(seniority: id, yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: ""),
            sourceText: resume, readableText: resume,
            coverLetterText: cover, coverLetterReadableText: cover,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func loadsSavedProfilesAndOffersPicker() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        try await repo.save(savedProfile(id: "p1", name: "One", resume: "R1"))
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: RecordingGenProvider()),
            loadProfiles: LoadProfilesUseCase(repository: repo)
        )
        #expect(vm.canPickProfile == false)      // nothing loaded yet
        await vm.loadSavedProfiles()
        #expect(vm.canPickProfile)
        #expect(vm.savedProfiles.map(\.id) == ["p1"])
    }

    @Test func resolvedTargetDefaultsToTheAmbientProfile() {
        let vm = ApplicationViewModel(generateApplication: GenerateApplicationUseCase(provider: RecordingGenProvider()))
        let ambient = PortfolioGrounding(resumeText: "ambient")
        let target = vm.resolvedTarget(fallbackProfile: profile, fallbackGrounding: ambient)
        #expect(target.profile.seniority == "S")   // the ambient/loaded profile, unchanged default
        #expect(target.grounding == ambient)
    }

    @Test func resolvedTargetUsesThePickedProfileAndItsGrounding() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        try await repo.save(savedProfile(id: "p1", name: "One", resume: "R1", cover: "C1"))
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: RecordingGenProvider()),
            loadProfiles: LoadProfilesUseCase(repository: repo)
        )
        await vm.loadSavedProfiles()
        vm.selectedProfileID = "p1"

        let target = vm.resolvedTarget(fallbackProfile: profile, fallbackGrounding: PortfolioGrounding(resumeText: "ambient"))
        #expect(target.profile.seniority == "p1")             // the picked profile's CandidateProfile
        #expect(target.grounding?.resumeText == "R1")         // grounded on ITS source documents
        #expect(target.grounding?.coverLetterText == "C1")
    }

    @Test func resolvedTargetFallsBackWhenPickIsGone() {
        let vm = ApplicationViewModel(generateApplication: GenerateApplicationUseCase(provider: RecordingGenProvider()))
        vm.selectedProfileID = "missing"                      // set, but never loaded
        let target = vm.resolvedTarget(fallbackProfile: profile, fallbackGrounding: nil)
        #expect(target.profile.seniority == "S")              // safe fallback to the ambient profile
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
        #expect(vm.exportData(.resume, .markdown) == nil)
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

        #expect(vm.exportData(.resume, .pdf) == nil)   // unsupported format degrades to nil, no crash
    }

    @Test func exportWithoutAnExporterIsUnavailable() async {
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(kitResume: "R"))
        )
        await vm.generate(for: job, profile: profile)
        #expect(vm.kit != nil)
        #expect(vm.canExport == false)        // no exporter wired
        #expect(vm.exportData(.resume, .markdown) == nil)
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
        _ = vm.exportData(.resume, .pdf)
        #expect(exporter.lastExportTemplate == .modern)
    }

    // MARK: Milestone G — résumé + cover letter export as separate documents

    @Test func perDocumentExportAvailabilityAndFilenames() async {
        let vm = exportVM()
        await vm.generate(for: JobListing(id: "x", title: "iOS Engineer", company: "Acme", location: "l", description: "d"),
                          profile: profile)
        #expect(vm.canExport(.resume))                     // the stub generates a résumé
        #expect(vm.exportData(.resume, .markdown) != nil)
        #expect(vm.exportFilename(for: .resume, .pdf) == "Acme - iOS Engineer - Résumé.pdf")
        #expect(vm.exportFilename(for: .coverLetter, .docx) == "Acme - iOS Engineer - Cover Letter.docx")
    }

    @Test func absentDocumentIsNotExportable() async {
        // The stub produces a résumé but no cover letter → cover letter isn't offered.
        let vm = exportVM()
        await vm.generate(for: job, profile: profile)
        #expect(vm.canExport(.coverLetter) == false)
        #expect(vm.exportData(.coverLetter, .markdown) == nil)
    }

    // MARK: Milestone I — additional-context box

    @Test func applyingAPresetClearsTypedAdditionalContext() {
        let vm = exportVM()
        vm.generationSettings.additionalContext = "steer this specific job"
        vm.applyPreset(GenerationPreset(id: "p", name: "Curated",
                                        settings: GenerationSettings(fidelity: 0.5),
                                        createdAt: Date(timeIntervalSince1970: 0)))
        #expect(vm.generationSettings.fidelity == 0.5)          // preset's controls applied
        #expect(vm.generationSettings.additionalContext == "")  // per-job free-text is not carried by presets
    }

    // MARK: Milestone D — awesome-cv LaTeX export

    private func latexVM(compiler: any LaTeXCompiling) -> ApplicationViewModel {
        ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(kitResume: "# Resume\nSwift dev")),
            exportApplication: ExportApplicationUseCase(exporter: MarkdownDocumentExporter(), compiler: compiler)
        )
    }

    @Test func laTeXExportGatingReflectsAvailabilityAndPresence() async {
        let vm = latexVM(compiler: VMStubCompiler(available: true))
        #expect(vm.canExportLaTeX == false)                     // no kit yet
        await vm.generate(for: job, profile: profile)
        #expect(vm.canExportLaTeX)                              // available + kit
        #expect(vm.canExportLaTeX(.resume))                    // résumé present
        #expect(vm.canExportLaTeX(.coverLetter) == false)      // stub produces no cover letter
    }

    @Test func laTeXUnavailableWhenCompilerReportsUnavailable() async {
        let vm = latexVM(compiler: VMStubCompiler(available: false))
        await vm.generate(for: job, profile: profile)
        #expect(vm.canExportLaTeX == false)
        #expect(vm.canExportLaTeX(.resume) == false)
    }

    // MARK: Document styles at export time (v0.7.0 Milestone E)

    /// A VM with a styles library behind it, so the picker has something to pick.
    private func styledVM(compiler: VMStubCompiler,
                          styles: [SavedDocumentStyle],
                          defaultID: String? = nil) async -> ApplicationViewModel {
        let store = InMemoryRecordStore()
        let repo = SavedDocumentStylesRepository(store: store)
        for style in styles { try? await repo.save(style) }
        let defaults = PresentationMemoryStore()
        let pointer = DefaultDocumentStyleStore(store: defaults)
        pointer.save(defaultID)

        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(
                provider: PresentationStubProvider(kitResume: "# Resume\nSwift dev")),
            exportApplication: ExportApplicationUseCase(exporter: MarkdownDocumentExporter(), compiler: compiler),
            loadDocumentStyles: LoadDocumentStylesUseCase(repository: repo),
            defaultDocumentStyleStore: pointer
        )
        await vm.generate(for: job, profile: profile)
        await vm.loadDocumentStyles()
        return vm
    }

    private func savedStyle(_ id: String, leftCm: Double) -> SavedDocumentStyle {
        var style = LaTeXStyle.default
        style.margins = LaTeXMargins(leftCm: leftCm, topCm: 1, rightCm: 1, bottomCm: 1, footskipCm: 0.25)
        return SavedDocumentStyle(id: id, name: "Style \(id)", style: style,
                                  createdAt: Date(timeIntervalSince1970: 1))
    }

    /// The core contract of the milestone: what the picker selects is what the export compiles.
    @Test func latexPDFExportUsesTheSelectedSavedStyle() async {
        let compiler = VMStubCompiler()
        let vm = await styledVM(compiler: compiler, styles: [savedStyle("s1", leftCm: 2)])
        vm.selectedStyleChoice = .saved("s1")
        _ = await vm.exportLaTeXPDF(.resume)

        #expect(compiler.lastTex?.contains("left=2.00cm") == true)
    }

    /// …and through the `.tex` source route, which needs no TeX install at all.
    @Test func texSourceExportUsesTheSelectedSavedStyle() async {
        let vm = await styledVM(compiler: VMStubCompiler(available: false),
                                styles: [savedStyle("s1", leftCm: 2)])
        vm.selectedStyleChoice = .saved("s1")
        let tex = String(decoding: vm.exportTexSource(.resume) ?? Data(), as: UTF8.self)

        #expect(tex.contains("left=2.00cm"))
    }

    @Test func styleSelectionDefaultsToTheDefaultPointer() async {
        let vm = await styledVM(compiler: VMStubCompiler(),
                                styles: [savedStyle("s1", leftCm: 2), savedStyle("s2", leftCm: 3)],
                                defaultID: "s2")
        #expect(vm.selectedStyleChoice == nil)
        #expect(vm.resolvedStyle.margins.leftCm == 3)
        #expect(vm.defaultStyleRowLabel == "Default — Style s2")
    }

    /// A pointer to a deleted style falls back to the **built-in** look — never to another saved
    /// style, which would silently restyle the document the user is about to send.
    @Test func aDanglingDefaultPointerFallsBackToTheBuiltInStyle() async {
        let vm = await styledVM(compiler: VMStubCompiler(),
                                styles: [savedStyle("s1", leftCm: 2)],
                                defaultID: "deleted-id")
        #expect(vm.resolvedStyle == .default)
        #expect(vm.resolvedStyle.margins.leftCm != 2)
        #expect(vm.defaultStyleRowLabel == "Default — \(LaTeXTemplateRegistry.fallback.displayName)")
    }

    @Test func pickingABuiltInTemplateUsesItsDefaultStyle() async {
        let compiler = VMStubCompiler()
        let vm = await styledVM(compiler: compiler, styles: [])
        vm.selectedStyleChoice = .builtIn(.awesomeCVCompact)
        _ = await vm.exportLaTeXPDF(.resume)

        #expect(compiler.lastTex?.contains("left=0.35cm") == true)
    }

    /// With no library wired at all, the export is byte-for-byte the pre-v0.7.0 output.
    @Test func withoutAStylesLibraryTheExportIsTheBuiltInDefault() async {
        let vm = latexVM(compiler: VMStubCompiler(available: false))
        await vm.generate(for: job, profile: profile)
        let tex = String(decoding: vm.exportTexSource(.resume) ?? Data(), as: UTF8.self)

        #expect(vm.savedStyles.isEmpty)
        #expect(vm.resolvedStyle == .default)
        #expect(tex == TexDocumentBuilder.resume(fromMarkdown: "# Resume\nSwift dev"))
    }

    /// The "compiled to N pages" advisory was measured under the old style — changing style must
    /// retire it rather than leave it advising against a style the user no longer has selected.
    @Test func changingTheStyleClearsTheStaleCompiledPageCount() async throws {
        let realPDF = try PDFDocumentExporter().export(markdown: "# R\n\nbody", as: .pdf)
        let vm = await styledVM(compiler: VMStubCompiler(result: .success(realPDF)),
                                styles: [savedStyle("s1", leftCm: 2)])
        _ = await vm.exportLaTeXPDF(.resume)
        #expect(vm.latexResumePages == 1)

        vm.selectedStyleChoice = .saved("s1")
        #expect(vm.latexResumePages == 0)
        #expect(vm.exportError == nil)
    }

    // MARK: The custom-preamble escape at export time (v0.7.0 Milestone F)

    private func overriddenStyle(_ id: String) -> SavedDocumentStyle {
        var style = LaTeXStyle.default
        style.customPreamble = "\\thisIsNotACommand{}"
        return SavedDocumentStyle(id: id, name: "Broken", style: style,
                                  createdAt: Date(timeIntervalSince1970: 1))
    }

    /// A compile failure under a custom preamble names it as the likely cause — the log alone
    /// doesn't tell a user which of their choices did this.
    @Test func aCompileFailureUnderAnOverrideNamesThePreamble() async {
        let vm = await styledVM(compiler: VMStubCompiler(
            result: .failure(LaTeXProcessError.nonZeroExit(code: 1, log: "! Undefined control sequence"))),
            styles: [overriddenStyle("s1")])
        vm.selectedStyleChoice = .saved("s1")
        _ = await vm.exportLaTeXPDF(.resume)

        #expect(vm.exportUsedCustomPreamble)
        #expect(vm.exportError?.contains("! Undefined control sequence") == true)
        #expect(vm.exportError?.contains("custom LaTeX preamble") == true)
    }

    /// …and the one-click escape unblocks the send without editing or deleting the style.
    @Test func theBuiltInEscapeUnblocksTheExportWithoutTouchingTheStyle() async {
        let compiler = VMStubCompiler()
        let vm = await styledVM(compiler: compiler, styles: [overriddenStyle("s1")])
        vm.selectedStyleChoice = .saved("s1")
        #expect(vm.exportUsedCustomPreamble)

        vm.useBuiltInStyleForExport()

        #expect(!vm.exportUsedCustomPreamble)
        #expect(vm.resolvedStyle == LaTeXStyle.default)
        _ = await vm.exportLaTeXPDF(.resume)
        #expect(compiler.lastTex?.contains("thisIsNotACommand") == false)
        // The user's style is untouched — the escape is session-only.
        #expect(vm.savedStyles.first?.style.customPreamble != nil)
    }

    /// The `.tex` source keeps working when the PDF route can't — that's how a broken preamble
    /// gets debugged.
    @Test func theTexSourceStillExportsUnderABrokenOverride() async {
        let vm = await styledVM(compiler: VMStubCompiler(available: false),
                                styles: [overriddenStyle("s1")])
        vm.selectedStyleChoice = .saved("s1")
        let tex = String(decoding: vm.exportTexSource(.resume) ?? Data(), as: UTF8.self)

        #expect(tex.contains("\\thisIsNotACommand{}"))
        #expect(tex.contains("\\begin{document}"))
    }

    @Test func exportLaTeXPDFReturnsBytesAndRecordsRealPageCount() async throws {
        let realPDF = try PDFDocumentExporter().export(markdown: "# R\n\nbody", as: .pdf)   // a valid one-page PDF
        let vm = latexVM(compiler: VMStubCompiler(result: .success(realPDF)))
        await vm.generate(for: job, profile: profile)
        let out = await vm.exportLaTeXPDF(.resume)
        #expect(out == realPDF)
        #expect(vm.latexResumePages == 1)
        #expect(vm.latexResumeExceedsOnePage == false)
        #expect(vm.exportError == nil)
    }

    @Test func exportLaTeXPDFSurfacesCompileErrors() async {
        let vm = latexVM(compiler: VMStubCompiler(
            result: .failure(LaTeXProcessError.nonZeroExit(code: 1, log: "! Undefined control sequence."))))
        await vm.generate(for: job, profile: profile)
        let out = await vm.exportLaTeXPDF(.resume)
        #expect(out == nil)
        #expect(vm.exportError?.contains("Undefined control sequence") == true)
    }

    @Test func texSourceExportsWithoutTeXButRespectsPresence() async {
        let vm = latexVM(compiler: VMStubCompiler(available: false))   // no lualatex
        await vm.generate(for: job, profile: profile)
        let tex = vm.exportTexSource(.resume)
        #expect(tex != nil)                                            // .tex source doesn't need a TeX install
        #expect(String(decoding: tex ?? Data(), as: UTF8.self).contains("Class/Resume"))
        #expect(vm.exportTexSource(.coverLetter) == nil)              // absent document
        #expect(vm.texFilename(for: .resume).hasSuffix(" - Résumé.tex"))
    }

    @Test func pdfPageCountReadsRealPDFsAndDegradesToZero() throws {
        let realPDF = try PDFDocumentExporter().export(markdown: "# R\n\nbody", as: .pdf)
        #expect(ApplicationViewModel.pdfPageCount(realPDF) == 1)
        #expect(ApplicationViewModel.pdfPageCount(Data("not a pdf".utf8)) == 0)
    }
}
