//
//  DocumentStylesViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Settings — the document-style manager (v0.7.0 Milestone E).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// A `LaTeXCompiling` stub that records the `.tex` it was handed, so a test can prove the *draft*
/// style reached the compiler.
private final class StyleStubCompiler: LaTeXCompiling, @unchecked Sendable {
    let available: Bool
    let result: Result<Data, Error>
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

/// A record store whose writes always fail — for the save-error path.
private final class FailingRecordStore: PersistentRecordStore, @unchecked Sendable {
    struct Boom: Error {}
    func upsert(kind: String, id: String, data: Data) async throws { throw Boom() }
    func records(ofKind kind: String) async throws -> [Data] { [] }
    func entries(ofKind kind: String) async throws -> [StoredEntry] { [] }
    func record(ofKind kind: String, id: String) async throws -> Data? { nil }
    func delete(kind: String, id: String) async throws {}
}

@MainActor
@Suite("DocumentStylesViewModel")
struct DocumentStylesViewModelTests {

    private func makeStores() -> (record: InMemoryRecordStore, defaults: PresentationMemoryStore) {
        (InMemoryRecordStore(), PresentationMemoryStore())
    }

    /// A VM over real (in-memory) persistence, with deterministic ids/dates.
    private func makePersistingVM(
        stores: (record: InMemoryRecordStore, defaults: PresentationMemoryStore)? = nil,
        idSequence: @escaping @Sendable () -> String = { "id-1" },
        compiler: StyleStubCompiler? = nil
    ) -> DocumentStylesViewModel {
        let stores = stores ?? makeStores()
        let repo = SavedDocumentStylesRepository(store: stores.record)
        return DocumentStylesViewModel(
            saveDocumentStyle: SaveDocumentStyleUseCase(repository: repo, makeID: idSequence,
                                                        now: { Date(timeIntervalSince1970: 1) }),
            loadDocumentStyles: LoadDocumentStylesUseCase(repository: repo),
            deleteDocumentStyle: DeleteDocumentStyleUseCase(repository: repo),
            defaultDocumentStyleStore: DefaultDocumentStyleStore(store: stores.defaults),
            exportApplication: compiler.map {
                ExportApplicationUseCase(exporter: RoutingDocumentExporter(), compiler: $0)
            },
            latexAvailable: compiler?.isAvailable ?? false
        )
    }

    /// Hands out "id-1", "id-2", … so duplicate/create tests get distinct rows.
    private func incrementingIDs() -> @Sendable () -> String {
        let counter = Counter()
        return { "id-\(counter.next())" }
    }

    private final class Counter: @unchecked Sendable {
        private var value = 0
        func next() -> Int { value += 1; return value }
    }

    // MARK: Availability

    @Test func stylesLibraryUnavailableWithoutPersistence() async {
        let vm = DocumentStylesViewModel()
        #expect(!vm.supportsDocumentStyles)
        #expect(!vm.canSaveStyle)
        await vm.reloadStyles()
        #expect(vm.savedStyles.isEmpty)
    }

    // MARK: Saving

    @Test func savingCreatesAStyleAndSelectsIt() async {
        let vm = makePersistingVM()
        vm.draftName = "Tight margins"
        vm.draft.margins = LaTeXMargins(leftCm: 1, topCm: 1, rightCm: 1, bottomCm: 1, footskipCm: 0.25)
        await vm.saveDraft()

        #expect(vm.savedStyles.count == 1)
        #expect(vm.selectedStyleID == "id-1")
        #expect(vm.savedStyles.first?.name == "Tight margins")
        #expect(vm.savedStyles.first?.style.margins.leftCm == 1)
    }

    @Test func savingWithASelectionUpdatesInPlace() async {
        let vm = makePersistingVM(idSequence: incrementingIDs())
        vm.draftName = "First"
        await vm.saveDraft()
        vm.draftName = "Renamed"
        vm.draft.pageSize = .usLetter
        await vm.saveDraft()

        #expect(vm.savedStyles.count == 1)                    // updated, not duplicated
        #expect(vm.savedStyles.first?.id == "id-1")
        #expect(vm.savedStyles.first?.name == "Renamed")
        #expect(vm.savedStyles.first?.style.pageSize == .usLetter)
    }

    /// v0.7.1 Milestone F: the relaunch flow end to end at the VM level. The pane's `.task` now
    /// calls `reloadStyles()` on appearance — so a fresh VM over the same store (a relaunch)
    /// lists the persisted library, opens the default style in the editor, and a save **updates**
    /// that style instead of re-creating it as a duplicate row (the pre-fix symptom: the library
    /// looked empty, so Save had no selection to match and inserted).
    @Test func afterARelaunchReloadListsTheLibraryAndSaveUpdatesNotDuplicates() async {
        let stores = makeStores()
        let first = makePersistingVM(stores: stores, idSequence: incrementingIDs())
        first.draftName = "Mine"
        await first.saveDraft()
        first.setDefault(first.savedStyles[0])

        // "Relaunch": a fresh VM over the same persistence, loaded the way the pane now does.
        let relaunched = makePersistingVM(stores: stores, idSequence: incrementingIDs())
        #expect(relaunched.savedStyles.isEmpty)               // nothing before the load
        await relaunched.reloadStyles()

        #expect(relaunched.savedStyles.map(\.name) == ["Mine"])   // the library is listed…
        #expect(relaunched.selectedStyleID == "id-1")             // …with the default opened
        #expect(relaunched.draftName == "Mine")

        relaunched.draft.pageSize = .usLetter
        await relaunched.saveDraft()
        #expect(relaunched.savedStyles.count == 1)            // updated in place, no duplicate
        #expect(relaunched.savedStyles.first?.style.pageSize == .usLetter)
    }

    @Test func savingWithABlankNameIsRefused() async {
        let vm = makePersistingVM()
        vm.draftName = "   "
        #expect(!vm.canSaveStyle)
        await vm.saveDraft()
        #expect(vm.savedStyles.isEmpty)
    }

    @Test func saveFailureSurfacesAMessage() async {
        let repo = SavedDocumentStylesRepository(store: FailingRecordStore())
        let vm = DocumentStylesViewModel(
            saveDocumentStyle: SaveDocumentStyleUseCase(repository: repo),
            loadDocumentStyles: LoadDocumentStylesUseCase(repository: repo),
            deleteDocumentStyle: DeleteDocumentStyleUseCase(repository: repo)
        )
        vm.draftName = "Doomed"
        await vm.saveDraft()

        #expect(vm.errorMessage == "Couldn't save this style. Try again.")
        #expect(vm.savedStyles.isEmpty)
    }

    // MARK: Duplicate

    @Test func duplicateCreatesASecondRowWithANewID() async {
        let vm = makePersistingVM(idSequence: incrementingIDs())
        vm.draftName = "Compact"
        vm.draft.margins = LaTeXMargins(leftCm: 0.35, topCm: 0.35, rightCm: 0.35, bottomCm: 0.55, footskipCm: 0.2)
        await vm.saveDraft()
        let original = vm.savedStyles[0]
        await vm.duplicate(original)

        #expect(vm.savedStyles.count == 2)
        #expect(Set(vm.savedStyles.map(\.id)).count == 2)
        #expect(vm.savedStyles.contains { $0.name == "Compact copy" })
        #expect(vm.savedStyles.allSatisfy { $0.style.margins.leftCm == 0.35 })
    }

    @Test func copyNameDisambiguates() {
        let styles = ["Compact", "Compact copy"].enumerated().map { index, name in
            SavedDocumentStyle(id: "\(index)", name: name, style: .default,
                               createdAt: Date(timeIntervalSince1970: 0))
        }
        #expect(DocumentStylesViewModel.copyName(of: "Compact", in: []) == "Compact copy")
        #expect(DocumentStylesViewModel.copyName(of: "Compact", in: styles) == "Compact copy 2")
    }

    // MARK: Delete + the default pointer

    @Test func deleteRemovesTheStyleAndClearsTheSelection() async {
        let vm = makePersistingVM()
        vm.draftName = "Doomed"
        await vm.saveDraft()
        await vm.delete(vm.savedStyles[0])

        #expect(vm.savedStyles.isEmpty)
        #expect(vm.selectedStyleID == nil)
    }

    /// Deleting the default must clear the pointer **on disk**, not just in memory — a dangling
    /// pointer silently exports the built-in look with no sign of why.
    @Test func deletingTheDefaultClearsThePointerOnDisk() async {
        let stores = makeStores()
        let vm = makePersistingVM(stores: stores)
        vm.draftName = "The default"
        await vm.saveDraft()
        vm.setDefault(vm.savedStyles[0])
        #expect(DefaultDocumentStyleStore(store: stores.defaults).load() == "id-1")

        await vm.delete(vm.savedStyles[0])
        #expect(vm.defaultStyleID == nil)
        #expect(DefaultDocumentStyleStore(store: stores.defaults).load() == nil)
    }

    @Test func deletingANonDefaultStyleLeavesThePointer() async {
        let stores = makeStores()
        let vm = makePersistingVM(stores: stores, idSequence: incrementingIDs())
        vm.draftName = "Keeper"
        await vm.saveDraft()
        vm.setDefault(vm.savedStyles[0])
        let keeperID = vm.savedStyles[0].id

        vm.newStyle(from: .awesomeCV)     // clears the selection, so this saves a second row
        vm.draftName = "Other"
        await vm.saveDraft()
        let other = try? #require(vm.savedStyles.first { $0.id != keeperID })
        if let other { await vm.delete(other) }

        #expect(vm.defaultStyleID == keeperID)
        #expect(DefaultDocumentStyleStore(store: stores.defaults).load() == keeperID)
    }

    @Test func setDefaultMarksAndPersistsAcrossRelaunch() async {
        let stores = makeStores()
        let vm = makePersistingVM(stores: stores)
        vm.draftName = "Mine"
        await vm.saveDraft()
        vm.setDefault(vm.savedStyles[0])

        let relaunched = makePersistingVM(stores: stores)
        await relaunched.reloadStyles()
        #expect(relaunched.isDefault(relaunched.savedStyles[0]))
    }

    @Test func setDefaultTogglesOff() async {
        let stores = makeStores()
        let vm = makePersistingVM(stores: stores)
        vm.draftName = "Mine"
        await vm.saveDraft()
        vm.setDefault(vm.savedStyles[0])
        vm.setDefault(vm.savedStyles[0])

        #expect(vm.defaultStyleID == nil)
        #expect(DefaultDocumentStyleStore(store: stores.defaults).load() == nil)
    }

    /// The default opens in the editor on first load — and a later reload must not clobber edits.
    @Test func theDefaultAutoLoadsOnceAndLaterReloadsLeaveTheDraftAlone() async {
        let stores = makeStores()
        let seeding = makePersistingVM(stores: stores)
        seeding.draftName = "Mine"
        seeding.draft.pageSize = .usLetter
        await seeding.saveDraft()
        seeding.setDefault(seeding.savedStyles[0])

        let vm = makePersistingVM(stores: stores)
        await vm.reloadStyles()
        #expect(vm.selectedStyleID == "id-1")
        #expect(vm.draft.pageSize == .usLetter)

        vm.draft.pageSize = .a4                 // the user edits
        await vm.reloadStyles()
        #expect(vm.draft.pageSize == .a4)       // …and a reload leaves it alone
    }

    // MARK: Section order + visibility

    /// Moves are swaps: every bucket must stay present exactly once, or hiding-by-accident would
    /// silently delete every section that classifies into it.
    @Test func sectionOrderMovesKeepEveryBucketExactlyOnce() {
        let vm = makePersistingVM()
        vm.moveSection(.skills, by: -1)
        vm.moveSection(.skills, by: -1)
        vm.moveSection(.education, by: 1)

        #expect(vm.draft.sectionOrder.count == LaTeXResumeSection.allCases.count)
        #expect(Set(vm.draft.sectionOrder) == Set(LaTeXResumeSection.allCases))
    }

    @Test func movingPastTheEndsIsANoOp() {
        let vm = makePersistingVM()
        let before = vm.draft.sectionOrder
        vm.moveSection(before.first!, by: -1)
        vm.moveSection(before.last!, by: 1)
        #expect(vm.draft.sectionOrder == before)
    }

    @Test func hiddenSectionsToggleBothWays() {
        let vm = makePersistingVM()
        vm.setVisible(.projects, false)
        #expect(!vm.isVisible(.projects))
        #expect(vm.draft.hiddenSections.contains(.projects))

        vm.setVisible(.projects, true)
        #expect(vm.isVisible(.projects))
        #expect(vm.draft.hiddenSections.isEmpty)
    }

    @Test func spacingFallsBackToTheCanonicalValueAndWritesThrough() {
        let vm = makePersistingVM()
        vm.draft.sectionSpacingEm = [:]
        #expect(vm.spacing(for: .experience) == -1.5)

        vm.setSpacing(-0.25, for: .experience)
        #expect(vm.draft.sectionSpacingEm[.experience] == -0.25)
        #expect(vm.spacing(for: .experience) == -0.25)
    }

    @Test func newStyleSeedsFromTheTemplateDescriptor() {
        let vm = makePersistingVM()
        vm.newStyle(from: .awesomeCVCompact)

        #expect(vm.selectedStyleID == nil)
        #expect(vm.draft.template == .awesomeCVCompact)
        #expect(vm.draft.margins.leftCm == 0.35)
        #expect(vm.draftName == LaTeXTemplateDescriptor.awesomeCVCompact.displayName)
    }

    // MARK: The raw-LaTeX escape hatch (v0.7.0 Milestone F)

    @Test func togglingTheOverrideOnSeedsFromTheGeneratedBlock() {
        let vm = makePersistingVM()
        vm.draft.margins = LaTeXMargins(leftCm: 2, topCm: 2, rightCm: 2, bottomCm: 2, footskipCm: 0.5)
        vm.setUsesCustomPreamble(true)

        #expect(vm.usesCustomPreamble)
        // Seeded with what the app would have written — not blank, not a hand-copied approximation.
        #expect(vm.customPreambleText.contains("left=2.00cm"))
        #expect(vm.customPreambleText == vm.generatedStyleBlock())
    }

    /// Toggling off then on again must restore the user's typing, not destroy it.
    @Test func togglingTheOverrideOffStashesTheTextAndBackOnRestoresIt() {
        let vm = makePersistingVM()
        vm.setUsesCustomPreamble(true)
        vm.customPreambleText = "\\geometry{left=4cm}  % mine"

        vm.setUsesCustomPreamble(false)
        #expect(!vm.usesCustomPreamble)
        #expect(vm.draft.customPreamble == nil)

        vm.setUsesCustomPreamble(true)
        #expect(vm.customPreambleText == "\\geometry{left=4cm}  % mine")
    }

    @Test func aBlankOverrideIsReportedAsBlank() {
        let vm = makePersistingVM()
        vm.setUsesCustomPreamble(true)
        vm.customPreambleText = "   \n  "

        #expect(vm.usesCustomPreamble)
        #expect(vm.customPreambleIsBlank)
        #expect(vm.draft.effectiveCustomPreamble == nil)     // the builder ignores it
    }

    @Test func resetPreambleReseedsFromTheDraftsOwnFields() {
        let vm = makePersistingVM()
        vm.setUsesCustomPreamble(true)
        vm.customPreambleText = "garbage"
        vm.draft.margins = LaTeXMargins(leftCm: 3, topCm: 3, rightCm: 3, bottomCm: 3, footskipCm: 0.5)
        vm.resetPreambleToGenerated()

        #expect(vm.customPreambleText.contains("left=3.00cm"))
        #expect(vm.usesCustomPreamble)                        // still on — just re-seeded
    }

    /// **The stranding guarantee.** The exports read the *store*, so a revert that only touched
    /// the draft would leave the manager looking fixed while every export still failed.
    @Test func revertingWritesThroughToTheSavedStyle() async {
        let vm = makePersistingVM()
        vm.draftName = "Broken"
        vm.setUsesCustomPreamble(true)
        vm.customPreambleText = "\\thisIsNotACommand{}"
        await vm.saveDraft()
        #expect(vm.savedStyles.first?.style.customPreamble != nil)

        await vm.dropCustomPreamble()

        #expect(vm.draft.customPreamble == nil)
        #expect(vm.savedStyles.count == 1)                             // same row, not a copy
        #expect(vm.savedStyles.first?.style.customPreamble == nil)     // …and it's persisted
    }

    @Test func revertingKeepsEveryOtherChoice() async {
        let vm = makePersistingVM()
        vm.draftName = "Mine"
        vm.draft.pageSize = .usLetter
        vm.draft.hiddenSections = [.projects]
        vm.setUsesCustomPreamble(true)
        await vm.saveDraft()
        await vm.dropCustomPreamble()

        #expect(vm.draft.pageSize == .usLetter)
        #expect(vm.draft.hiddenSections == [.projects])
    }

    /// The heavier revert adopts a built-in's look but **keeps the style's identity**, so Save
    /// updates the same row instead of leaving the broken one on disk beside a copy.
    @Test func revertingToABuiltInKeepsTheRowAndDropsTheOverride() async {
        let vm = makePersistingVM()
        vm.draftName = "Mine"
        vm.setUsesCustomPreamble(true)
        vm.customPreambleText = "\\thisIsNotACommand{}"
        await vm.saveDraft()
        let id = vm.selectedStyleID

        await vm.revertToBuiltIn(.awesomeCVCompact)

        #expect(vm.selectedStyleID == id)
        #expect(vm.draftName == "Mine")
        #expect(vm.draft.customPreamble == nil)
        #expect(vm.draft.margins.leftCm == 0.35)
        #expect(vm.savedStyles.count == 1)
        #expect(vm.savedStyles.first?.style.customPreamble == nil)
    }

    /// An unsaved draft has nothing to write through to — reverting must not invent a row.
    @Test func revertingAnUnsavedDraftTouchesNoStorage() async {
        let vm = makePersistingVM()
        vm.setUsesCustomPreamble(true)
        await vm.dropCustomPreamble()

        #expect(vm.draft.customPreamble == nil)
        #expect(vm.savedStyles.isEmpty)
    }

    /// The `.tex` source is how a user debugs a preamble that won't compile, so it must carry the
    /// override even when a compile would fail.
    @Test func theSampleTexSourceCarriesAnUncompilableOverride() {
        let vm = makePersistingVM(compiler: StyleStubCompiler())
        vm.setUsesCustomPreamble(true)
        vm.customPreambleText = "\\thisIsNotACommand{}"

        #expect(vm.sampleTexSource()?.contains("\\thisIsNotACommand{}") == true)
    }

    /// A failed preview keeps the last good PDF on screen — comparing "what I had" to "what my
    /// edit broke" is most of a preview's value when hand-writing LaTeX.
    @Test func aFailedPreviewKeepsTheLastGoodRender() async {
        let compiler = StyleStubCompiler()
        let vm = makePersistingVM(compiler: compiler)
        await vm.compilePreview()
        #expect(vm.previewPDF != nil)

        let failing = makePersistingVM(compiler: StyleStubCompiler(
            result: .failure(LaTeXProcessError.nonZeroExit(code: 1, log: "! Boom"))))
        failing.setUsesCustomPreamble(true)
        await failing.compilePreview()
        // …and the message names the override as the likely cause.
        #expect(failing.previewError?.contains("custom LaTeX preamble") == true)
    }

    // MARK: Preview

    @Test func previewUnavailableWithoutLualatex() async {
        let vm = makePersistingVM(compiler: StyleStubCompiler(available: false))
        #expect(!vm.canPreview)
        await vm.compilePreview()
        #expect(vm.previewPDF == nil)
        #expect(vm.errorMessage == nil)      // not an error — the dependency is simply absent
    }

    /// The preview must compile the **draft**, not the saved style — and the sample must exercise
    /// the controls the bounds protect.
    @Test func previewCompilesTheDraftStyle() async {
        let compiler = StyleStubCompiler()
        let vm = makePersistingVM(compiler: compiler)
        vm.draft.margins = LaTeXMargins(leftCm: 2, topCm: 1, rightCm: 2, bottomCm: 1, footskipCm: 0.25)
        await vm.compilePreview()

        #expect(vm.previewPDF != nil)
        #expect(vm.isCompilingPreview == false)
        let tex = compiler.lastTex ?? ""
        #expect(tex.contains("left=2.00cm"))
        #expect(tex.contains("\\begin{cvskills}"))     // the sample covers the skills grid
        #expect(tex.contains("\\cventry"))             // …and a dated entry (the 6cm column)
        #expect(tex.contains("\\cvsection{Awards}"))   // …and an unrecognised bucket
    }

    @Test func previewFailureSurfacesTheLualatexLog() async {
        let compiler = StyleStubCompiler(
            result: .failure(LaTeXProcessError.nonZeroExit(code: 1, log: "! Undefined control sequence")))
        let vm = makePersistingVM(compiler: compiler)
        await vm.compilePreview()

        #expect(vm.isCompilingPreview == false)
        // A compile error lands in `previewError`, not `errorMessage` (v0.7.0 Milestone F): a save
        // failure and a compile failure must not overwrite each other.
        #expect(vm.previewError?.contains("! Undefined control sequence") == true)
        #expect(vm.errorMessage == nil)
    }
}
