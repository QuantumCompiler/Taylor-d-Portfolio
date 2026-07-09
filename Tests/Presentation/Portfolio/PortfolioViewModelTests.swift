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

    /// A VM wired to a real (in-memory) saved-profile library + document tidying.
    private func makePersistingVM(importText: String = "IMPORTED") -> PortfolioViewModel {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        let provider = PresentationStubProvider()
        return PortfolioViewModel(
            buildProfile: BuildProfileUseCase(provider: provider),
            importPortfolio: ImportPortfolioUseCase(extractor: PresentationStubExtractor(text: importText)),
            tidyDocument: TidyDocumentUseCase(provider: provider),
            saveProfile: SaveProfileUseCase(repository: repo, makeID: { "id-1" }, now: { Date(timeIntervalSince1970: 1) }),
            loadProfiles: LoadProfilesUseCase(repository: repo),
            deleteProfile: DeleteProfileUseCase(repository: repo)
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
}
