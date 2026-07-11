//
//  PortfolioViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Portfolio
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@MainActor
@Suite("PortfolioViewModel")
struct PortfolioViewModelTests {

    private func makeVM(
        buildThrows: Bool = false,
        importText: String = "IMPORTED",
        importThrows: Bool = false
    ) -> PortfolioViewModel {
        PortfolioViewModel(
            buildProfile: BuildProfileUseCase(provider: PresentationStubProvider(shouldThrow: buildThrows)),
            importPortfolio: ImportPortfolioUseCase(extractor: PresentationStubExtractor(text: importText, shouldThrow: importThrows))
        )
    }

    /// Shared backing stores, so multiple VMs can see the same persisted state (used to
    /// prove a default/profile survives a "relaunch" into a fresh VM).
    private func makeStores() -> (record: InMemoryRecordStore, defaults: PresentationMemoryStore) {
        (InMemoryRecordStore(), PresentationMemoryStore())
    }

    /// A VM wired to real (in-memory) persistence + document tidying, over `stores`.
    private func makePersistingVM(
        importText: String = "IMPORTED",
        stores: (record: InMemoryRecordStore, defaults: PresentationMemoryStore)? = nil
    ) -> PortfolioViewModel {
        let stores = stores ?? makeStores()
        let repo = SavedProfilesRepository(store: stores.record)
        let provider = PresentationStubProvider()
        return PortfolioViewModel(
            buildProfile: BuildProfileUseCase(provider: provider),
            importPortfolio: ImportPortfolioUseCase(extractor: PresentationStubExtractor(text: importText)),
            tidyDocument: TidyDocumentUseCase(provider: provider),
            refineSummary: RefineSummaryUseCase(provider: provider),
            saveProfile: SaveProfileUseCase(repository: repo, makeID: { "id-1" }, now: { Date(timeIntervalSince1970: 1) }),
            loadProfiles: LoadProfilesUseCase(repository: repo),
            deleteProfile: DeleteProfileUseCase(repository: repo),
            defaultProfileStore: DefaultProfileStore(store: stores.defaults)
        )
    }

    @Test func buildSetsProfileOnSuccess() async {
        let vm = makeVM()
        vm.portfolioText = "my portfolio"
        await vm.build()
        #expect(vm.profile?.seniority == "BUILT")
        #expect(vm.errorMessage == nil)
        #expect(vm.isBuilding == false)
    }

    @Test func buildSetsErrorOnFailure() async {
        let vm = makeVM(buildThrows: true)
        vm.portfolioText = "text"
        await vm.build()
        #expect(vm.profile == nil)
        #expect(vm.errorMessage != nil)
    }

    @Test func canBuildRequiresNonEmptyText() {
        let vm = makeVM()
        #expect(vm.canBuild == false)
        vm.portfolioText = "   "
        #expect(vm.canBuild == false)
        vm.portfolioText = "real content"
        #expect(vm.canBuild == true)
    }

    @Test func importDocumentFillsPortfolioText() async {
        let vm = makeVM(importText: "EXTRACTED RESUME TEXT")
        await vm.importDocument(from: URL(fileURLWithPath: "/tmp/portfolio.pdf"))
        #expect(vm.portfolioText == "EXTRACTED RESUME TEXT")
        #expect(vm.errorMessage == nil)
        #expect(vm.isImporting == false)
    }

    @Test func importDocumentFailureSetsError() async {
        let vm = makeVM(importThrows: true)
        await vm.importDocument(from: URL(fileURLWithPath: "/tmp/broken.pdf"))
        #expect(vm.portfolioText.isEmpty)
        #expect(vm.errorMessage != nil)
        #expect(vm.isImporting == false)
    }

    // MARK: Saved-profile library

    @Test func buildPrefillsAName() async {
        let vm = makePersistingVM()
        vm.portfolioText = "text"
        await vm.build()
        #expect(vm.selectedProfileID == nil)          // freshly built, unsaved
        #expect(!vm.profileName.isEmpty)              // a default name is prefilled
        #expect(vm.canSaveProfile)
    }

    @Test func saveThenReloadPersistsAndSelects() async {
        let vm = makePersistingVM()
        vm.portfolioText = "text"
        await vm.build()
        vm.profileName = "Primary"
        await vm.saveProfile()

        #expect(vm.savedProfiles.map(\.name) == ["Primary"])
        #expect(vm.selectedProfileID == "id-1")       // now tracking the saved entry
    }

    @Test func selectLoadsSavedProfile() async {
        let vm = makePersistingVM()
        vm.portfolioText = "text"
        await vm.build()
        vm.profileName = "Primary"
        await vm.saveProfile()

        let saved = vm.savedProfiles[0]
        vm.select(saved)
        #expect(vm.profile == saved.profile)
        #expect(vm.profileName == "Primary")
        #expect(vm.selectedProfileID == saved.id)
    }

    @Test func toggleSelectionSelectsThenClears() async {
        let vm = makePersistingVM()
        vm.portfolioText = "text"
        await vm.build()
        vm.profileName = "Primary"
        await vm.saveProfile()
        let saved = vm.savedProfiles[0]

        // Re-tapping the loaded profile clears the radio and the active profile.
        vm.toggleSelection(saved)   // already selected after save → deselect
        #expect(vm.selectedProfileID == nil)
        #expect(vm.profile == nil)
        #expect(vm.readableText.isEmpty)

        // Tapping again re-loads it.
        vm.toggleSelection(saved)
        #expect(vm.selectedProfileID == saved.id)
        #expect(vm.profile == saved.profile)
    }

    @Test func deleteRemovesAndClearsSelection() async {
        let vm = makePersistingVM()
        vm.portfolioText = "text"
        await vm.build()
        vm.profileName = "Primary"
        await vm.saveProfile()

        await vm.delete(vm.savedProfiles[0])
        #expect(vm.savedProfiles.isEmpty)
        #expect(vm.selectedProfileID == nil)
    }

    @Test func savedProfilesUnavailableWithoutPersistence() {
        let vm = makeVM()
        #expect(vm.supportsSavedProfiles == false)
        #expect(vm.canSaveProfile == false)           // nothing to save into
    }

    // MARK: Default profile

    /// Builds + saves one profile, returning the VM and its saved entry.
    private func vmWithOneSavedProfile(
        stores: (record: InMemoryRecordStore, defaults: PresentationMemoryStore)
    ) async -> (PortfolioViewModel, SavedProfile) {
        let vm = makePersistingVM(stores: stores)
        vm.portfolioText = "text"
        await vm.build()
        vm.profileName = "Primary"
        await vm.saveProfile()
        return (vm, vm.savedProfiles[0])
    }

    @Test func setDefaultMarksAndPersistsAcrossRelaunch() async {
        let stores = makeStores()
        let (vm, saved) = await vmWithOneSavedProfile(stores: stores)

        vm.setDefault(saved)
        #expect(vm.isDefault(saved))
        #expect(vm.defaultProfileID == saved.id)

        // A fresh VM over the same stores reads the persisted default on init.
        let relaunched = makePersistingVM(stores: stores)
        #expect(relaunched.defaultProfileID == saved.id)
    }

    @Test func setDefaultTogglesOff() async {
        let stores = makeStores()
        let (vm, saved) = await vmWithOneSavedProfile(stores: stores)
        vm.setDefault(saved)
        vm.setDefault(saved)                 // long-press again clears it
        #expect(vm.defaultProfileID == nil)
        #expect(DefaultProfileStore(store: stores.defaults).load() == nil)
    }

    @Test func defaultAutoLoadsOnFreshLaunch() async {
        let stores = makeStores()
        let (vm, saved) = await vmWithOneSavedProfile(stores: stores)
        vm.setDefault(saved)

        // A brand-new VM (simulating relaunch) loads and auto-selects the default.
        let relaunched = makePersistingVM(stores: stores)
        await relaunched.reloadProfiles()
        #expect(relaunched.selectedProfileID == saved.id)
        #expect(relaunched.profile == saved.profile)
    }

    @Test func deletingTheDefaultClearsIt() async {
        let stores = makeStores()
        let (vm, saved) = await vmWithOneSavedProfile(stores: stores)
        vm.setDefault(saved)

        await vm.delete(saved)
        #expect(vm.defaultProfileID == nil)
        #expect(DefaultProfileStore(store: stores.defaults).load() == nil)
    }

    // MARK: Paired source document

    @Test func buildTidiesAndPairsTheSourceDocument() async {
        let vm = makePersistingVM()
        vm.portfolioText = "raw portfolio text"
        await vm.build()
        #expect(vm.sourceText == "raw portfolio text")          // what it was built on
        #expect(vm.readableText == "TIDY:\nraw portfolio text")  // reflowed by the engine
    }

    @Test func buildFallsBackToRawWhenNoTidyEngine() async {
        // makeVM() has no tidy use case wired.
        let vm = makeVM()
        vm.portfolioText = "raw text"
        await vm.build()
        #expect(vm.readableText == "raw text")
    }

    @Test func importRecordsSourceFileName() async {
        let vm = makePersistingVM(importText: "EXTRACTED")
        await vm.importDocument(from: URL(fileURLWithPath: "/tmp/resume.pdf"))
        #expect(vm.sourceFileName == "resume.pdf")
        await vm.build()
        #expect(vm.sourceText == "EXTRACTED")
    }

    @Test func savedDocumentRoundTripsThroughSelect() async {
        let vm = makePersistingVM(importText: "EXTRACTED RESUME")
        await vm.importDocument(from: URL(fileURLWithPath: "/tmp/cv.pdf"))
        await vm.build()
        vm.profileName = "Primary"
        await vm.saveProfile()

        let saved = vm.savedProfiles[0]
        #expect(saved.sourceFileName == "cv.pdf")
        #expect(saved.readableText == "TIDY:\nEXTRACTED RESUME")

        // Loading a different-looking VM state, then selecting, restores the document.
        vm.select(saved)
        #expect(vm.sourceFileName == "cv.pdf")
        #expect(vm.readableText == "TIDY:\nEXTRACTED RESUME")
    }

    // MARK: T-A — optional cover letter

    @Test func importCoverLetterFillsItsOwnSlotNotThePortfolio() async {
        let vm = makePersistingVM(importText: "COVER LETTER TEXT")
        await vm.importCoverLetter(from: URL(fileURLWithPath: "/tmp/letter.docx"))
        #expect(vm.coverLetterText == "COVER LETTER TEXT")
        #expect(vm.coverLetterFileName == "letter.docx")
        #expect(vm.portfolioText.isEmpty)          // the résumé slot is untouched
        #expect(vm.errorMessage == nil)
    }

    @Test func coverLetterDoesNotGateBuild() {
        let vm = makePersistingVM()
        vm.coverLetterText = "a letter"          // only the cover letter, no résumé
        #expect(vm.canBuild == false)            // still gated on the résumé/portfolio
        vm.portfolioText = "resume"
        #expect(vm.canBuild)
    }

    @Test func buildTidiesTheCoverLetterButKeepsTheProfileResumeOnly() async {
        let vm = makePersistingVM()
        vm.portfolioText = "raw resume"
        vm.coverLetterText = "raw letter"
        await vm.build()
        // Résumé grounding unchanged; profile still distilled from the résumé only.
        #expect(vm.sourceText == "raw resume")
        #expect(vm.profile?.seniority == "BUILT")
        // Cover letter captured + tidied alongside.
        #expect(vm.coverLetterSourceText == "raw letter")
        #expect(vm.coverLetterReadableText == "TIDY:\nraw letter")
    }

    @Test func buildWithoutACoverLetterLeavesItEmpty() async {
        let vm = makePersistingVM()
        vm.portfolioText = "raw resume"
        await vm.build()
        #expect(vm.coverLetterSourceText.isEmpty)
        #expect(vm.coverLetterReadableText.isEmpty)
        #expect(vm.coverLetterFileName == nil)
    }

    @Test func coverLetterRoundTripsThroughSaveAndSelect() async {
        let vm = makePersistingVM()
        vm.portfolioText = "resume"
        vm.coverLetterText = "my letter"
        await vm.importCoverLetter(from: URL(fileURLWithPath: "/tmp/note.txt"))  // sets file name (+ text)
        vm.coverLetterText = "my letter"        // keep deterministic raw text
        await vm.build()
        vm.profileName = "Primary"
        await vm.saveProfile()

        let saved = vm.savedProfiles[0]
        #expect(saved.coverLetterFileName == "note.txt")
        #expect(saved.coverLetterText == "my letter")
        #expect(saved.coverLetterReadableText == "TIDY:\nmy letter")

        vm.deselect()
        #expect(vm.coverLetterReadableText.isEmpty)
        vm.select(saved)
        #expect(vm.coverLetterFileName == "note.txt")
        #expect(vm.coverLetterSourceText == "my letter")
        #expect(vm.coverLetterReadableText == "TIDY:\nmy letter")
    }

    // MARK: Regenerate the profile summary

    @Test func regenerateSummaryRewritesOnlyTheSummary() async {
        let vm = makePersistingVM()
        vm.portfolioText = "raw resume"
        await vm.build()
        let before = vm.profile!
        vm.summaryPrompt = "more concise"

        await vm.regenerateSummary()

        #expect(vm.profile?.summary == "REFINED:more concise")   // summary replaced
        #expect(vm.profile?.seniority == before.seniority)        // other fields untouched
        #expect(vm.profile?.coreSkills == before.coreSkills)
        #expect(vm.summaryPrompt.isEmpty)                          // input cleared after submit
        #expect(vm.errorMessage == nil)
        #expect(vm.isRefiningSummary == false)
    }

    @Test func regenerateSummaryNeedsAProfileAndAWiredEngine() async {
        let unwired = makeVM()               // no refineSummary use case
        #expect(unwired.supportsSummaryRegeneration == false)
        #expect(unwired.canRegenerateSummary == false)

        let vm = makePersistingVM()
        #expect(vm.supportsSummaryRegeneration)
        #expect(vm.canRegenerateSummary == false)   // no profile yet
        vm.portfolioText = "resume"
        await vm.build()
        #expect(vm.canRegenerateSummary)            // profile built → enabled
    }

    @Test func regenerateSummaryWithAnEmptyPromptStillRegenerates() async {
        let vm = makePersistingVM()
        vm.portfolioText = "resume"
        await vm.build()
        vm.summaryPrompt = ""                       // empty prompt allowed → fresh rewrite
        await vm.regenerateSummary()
        #expect(vm.profile?.summary == "REFINED:")  // stub echoes the (empty) instruction
    }
}
