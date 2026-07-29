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

/// A `LaTeXCompiling` stub for the awesome-cv export path (Milestone D).
private final class VMStubCompiler: LaTeXCompiling, @unchecked Sendable {
    let available: Bool
    let result: Result<Data, Error>
    init(available: Bool = true, result: Result<Data, Error> = .success(Data("%PDF".utf8))) {
        self.available = available
        self.result = result
    }
    var isAvailable: Bool { available }
    func compile(tex: String, jobName: String) async throws -> Data { try result.get() }
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
