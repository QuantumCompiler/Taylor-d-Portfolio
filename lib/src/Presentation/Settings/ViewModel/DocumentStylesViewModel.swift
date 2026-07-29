//
//  DocumentStylesViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings — the document-style manager's state (v0.7.0 Milestone E).
//

import Foundation

/// Drives the **Document Styles** manager: the saved-style library plus the draft being edited by
/// the four control groups (typography / accent / geometry + page size / section order).
///
/// Its own view model rather than part of `SettingsViewModel`: that one loads synchronously in
/// `init` and defers writes to an explicit `save()`, which is right for engine settings and wrong
/// for a library — a user who edits a style and switches sub-tab must not lose it. This writes
/// through on every action, mirroring the saved-profile library.
///
/// Every dependency is optional: persistence degrades to off when the record store can't be built,
/// exactly as the profile and preset libraries do.
@MainActor
@Observable
final class DocumentStylesViewModel {

    /// The saved library, newest first (as the repository returns it).
    private(set) var savedStyles: [SavedDocumentStyle] = []
    /// The style being edited — what every control group binds into.
    var draft: LaTeXStyle = .default
    /// The name the draft saves under.
    var draftName: String = ""
    /// The saved style the draft came from; `nil` means "Save" creates a new one.
    private(set) var selectedStyleID: String?
    /// The user's default style, or `nil` when none is set.
    private(set) var defaultStyleID: String?
    private(set) var errorMessage: String?

    /// Preview state — the compiled sample and whether a compile is in flight. Its own flag, not
    /// `ApplicationViewModel.isCompilingLaTeX`: the two compile independently (each `lualatex` run
    /// gets its own staged directory), so one must not disable the other.
    private(set) var previewPDF: Data?
    private(set) var isCompilingPreview = false

    /// The built-in templates whose class files actually shipped — resolved in the composition
    /// root, because checking is file I/O.
    let templates: [LaTeXTemplateDescriptor]
    /// Whether `lualatex` was found (drives the Preview button's enabled state).
    let latexAvailable: Bool

    /// The compile error from the last Preview — kept **separate** from `errorMessage` so a save
    /// failure and a compile failure can't overwrite each other.
    private(set) var previewError: String?

    /// The typed preamble, stashed across a toggle-off so turning the override back on restores
    /// the user's text instead of destroying it. Session-only, never persisted.
    private var stashedPreamble: String?

    private var hasAppliedDefault = false
    private let saveDocumentStyle: SaveDocumentStyleUseCase?
    private let loadDocumentStyles: LoadDocumentStylesUseCase?
    private let deleteDocumentStyle: DeleteDocumentStyleUseCase?
    private let defaultDocumentStyleStore: DefaultDocumentStyleStore?
    private let exportApplication: ExportApplicationUseCase?

    init(
        saveDocumentStyle: SaveDocumentStyleUseCase? = nil,
        loadDocumentStyles: LoadDocumentStylesUseCase? = nil,
        deleteDocumentStyle: DeleteDocumentStyleUseCase? = nil,
        defaultDocumentStyleStore: DefaultDocumentStyleStore? = nil,
        exportApplication: ExportApplicationUseCase? = nil,
        templates: [LaTeXTemplateDescriptor] = LaTeXTemplateRegistry.all,
        latexAvailable: Bool = false
    ) {
        self.saveDocumentStyle = saveDocumentStyle
        self.loadDocumentStyles = loadDocumentStyles
        self.deleteDocumentStyle = deleteDocumentStyle
        self.defaultDocumentStyleStore = defaultDocumentStyleStore
        self.exportApplication = exportApplication
        self.templates = templates
        self.latexAvailable = latexAvailable
        self.defaultStyleID = defaultDocumentStyleStore?.load()
    }

    // MARK: Availability

    /// Whether the styles library is wired in this build (persistence can fail to initialise).
    var supportsDocumentStyles: Bool { loadDocumentStyles != nil && saveDocumentStyle != nil }

    /// Whether the draft can be saved — a style needs a name.
    var canSaveStyle: Bool {
        saveDocumentStyle != nil && !draftName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Whether a sample can be compiled (needs both a compiler and a TeX install).
    var canPreview: Bool { latexAvailable && exportApplication?.isLaTeXAvailable == true }

    // MARK: Library

    /// Loads the saved styles (call on appear). No-op when unavailable.
    func reloadStyles() async {
        guard let loadDocumentStyles else { return }
        savedStyles = (try? await loadDocumentStyles()) ?? savedStyles
        applyDefaultIfNeeded()
    }

    /// On the **first** load, open the user's default style in the editor — but never clobber a
    /// draft the user has already started (a second `reloadStyles()` leaves the editor alone).
    private func applyDefaultIfNeeded() {
        guard !hasAppliedDefault else { return }
        hasAppliedDefault = true
        guard selectedStyleID == nil,
              let defaultStyleID,
              let match = savedStyles.first(where: { $0.id == defaultStyleID })
        else { return }
        select(match)
    }

    /// Opens a saved style in the editor.
    func select(_ saved: SavedDocumentStyle) {
        selectedStyleID = saved.id
        draft = saved.style
        draftName = saved.name
        previewPDF = nil
        errorMessage = nil
    }

    /// Starts a new draft from a built-in template's defaults.
    func newStyle(from template: LaTeXTemplateID) {
        let descriptor = LaTeXTemplateRegistry.descriptor(for: template) ?? LaTeXTemplateRegistry.fallback
        selectedStyleID = nil
        draft = descriptor.defaultStyle
        draftName = SavedDocumentStyle.defaultName(for: descriptor.defaultStyle)
        previewPDF = nil
        errorMessage = nil
    }

    /// Saves the draft — updating the selected style in place, or creating a new one.
    func saveDraft() async {
        guard let saveDocumentStyle, canSaveStyle else { return }
        let name = draftName.trimmingCharacters(in: .whitespaces)
        let existing = selectedStyleID.flatMap { id in savedStyles.first { $0.id == id } }
        do {
            let saved = try await saveDocumentStyle(draft, name: name, existing: existing)
            selectedStyleID = saved.id
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't save this style. Try again."
        }
        await reloadStyles()
    }

    /// Saves a copy of `saved` under a disambiguated name, leaving the original untouched.
    func duplicate(_ saved: SavedDocumentStyle) async {
        guard let saveDocumentStyle else { return }
        do {
            let copy = try await saveDocumentStyle(saved.style,
                                                   name: Self.copyName(of: saved.name, in: savedStyles))
            selectedStyleID = copy.id
            draft = copy.style
            draftName = copy.name
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't duplicate this style. Try again."
        }
        await reloadStyles()
    }

    /// Deletes a saved style. Clears the editor if it was open and **clears the default pointer if
    /// it pointed here** — a dangling pointer would otherwise silently fall back to the built-in
    /// look with no sign of why.
    func delete(_ saved: SavedDocumentStyle) async {
        guard let deleteDocumentStyle else { return }
        try? await deleteDocumentStyle(id: saved.id)
        if selectedStyleID == saved.id {
            selectedStyleID = nil
            previewPDF = nil
        }
        if defaultStyleID == saved.id {
            defaultStyleID = nil
            defaultDocumentStyleStore?.save(nil)
        }
        await reloadStyles()
    }

    /// Whether `saved` is the default style.
    func isDefault(_ saved: SavedDocumentStyle) -> Bool { defaultStyleID == saved.id }

    /// Toggles `saved` as the default — setting it, or clearing it when it already was. Persisted,
    /// so the export picker preselects it next launch.
    func setDefault(_ saved: SavedDocumentStyle) {
        defaultStyleID = (defaultStyleID == saved.id) ? nil : saved.id
        defaultDocumentStyleStore?.save(defaultStyleID)
    }

    /// `"Compact"` → `"Compact copy"` → `"Compact copy 2"`, so duplicating twice doesn't produce
    /// two identically-named rows.
    static func copyName(of name: String, in existing: [SavedDocumentStyle]) -> String {
        let taken = Set(existing.map(\.name))
        let base = "\(name) copy"
        guard taken.contains(base) else { return base }
        var index = 2
        while taken.contains("\(base) \(index)") { index += 1 }
        return "\(base) \(index)"
    }

    // MARK: Section order (the one control that can lose data if done carelessly)

    /// Moves a bucket one place earlier/later in the draft's order. A **swap**, so every bucket
    /// stays present exactly once — dropping one would silently delete every section that
    /// classifies into it from every résumé.
    func moveSection(_ section: LaTeXResumeSection, by offset: Int) {
        guard let index = draft.sectionOrder.firstIndex(of: section) else { return }
        let target = index + offset
        guard draft.sectionOrder.indices.contains(target) else { return }
        draft.sectionOrder.swapAt(index, target)
    }

    /// Whether `section` is currently rendered.
    func isVisible(_ section: LaTeXResumeSection) -> Bool { !draft.hiddenSections.contains(section) }

    /// Shows/hides a section bucket in the draft.
    func setVisible(_ section: LaTeXResumeSection, _ visible: Bool) {
        if visible {
            draft.hiddenSections.remove(section)
        } else {
            draft.hiddenSections.insert(section)
        }
    }

    /// The draft's spacing for one bucket, falling back to the canonical value — the shape a
    /// `Slider`/`Stepper` binding needs.
    func spacing(for section: LaTeXResumeSection) -> Double {
        draft.sectionSpacingEm[section] ?? LaTeXResumeSection.canonicalSpacingEm[section] ?? -1
    }

    func setSpacing(_ value: Double, for section: LaTeXResumeSection) {
        draft.sectionSpacingEm[section] = value
    }

    // MARK: The raw-LaTeX escape hatch (v0.7.0 Milestone F)

    /// Whether the draft replaces the generated style block with the user's own LaTeX.
    var usesCustomPreamble: Bool { draft.customPreamble != nil }

    /// On, but empty — the builder falls back to the generated block, and the UI says so rather
    /// than letting the user compile an empty preamble and read `\normalsize is not defined`.
    var customPreambleIsBlank: Bool { usesCustomPreamble && draft.effectiveCustomPreamble == nil }

    /// The editor's text. A settable computed property is `@Bindable`-compatible under
    /// `@Observable`, and reading `draft` in the getter registers the dependency.
    var customPreambleText: String {
        get { draft.customPreamble ?? "" }
        set {
            draft.customPreamble = newValue
            stashedPreamble = newValue
        }
    }

    /// The style block the builder would emit for this draft with any override ignored — the
    /// editor's seed, so "what you're replacing" is exactly what the app would have written.
    func generatedStyleBlock() -> String {
        var base = draft
        base.customPreamble = nil
        return TexDocumentBuilder.styleBlock(base)
    }

    /// Turns the override on (seeded from the stash, else from the generated block) or off
    /// (stashing the text first — the user's typing is never silently destroyed).
    func setUsesCustomPreamble(_ enabled: Bool) {
        if enabled {
            draft.customPreamble = stashedPreamble ?? generatedStyleBlock()
        } else {
            stashedPreamble = draft.customPreamble
            draft.customPreamble = nil
        }
        previewError = nil
    }

    /// Re-seeds the editor from the draft's own fields, keeping the override on.
    func resetPreambleToGenerated() {
        draft.customPreamble = generatedStyleBlock()
        stashedPreamble = draft.customPreamble
        previewError = nil
    }

    /// **The one-click revert.** Drops the override, keeps every other choice — and writes through
    /// when a saved style is open, because the exports read the *store*, not this draft: a revert
    /// that only touched the draft would leave the manager looking fixed while every export still
    /// failed.
    func dropCustomPreamble() async {
        stashedPreamble = draft.customPreamble
        draft.customPreamble = nil
        previewError = nil
        guard selectedStyleID != nil else { return }
        guard canSaveStyle else {
            errorMessage = "Name this style and choose Save to apply the revert to your exports."
            return
        }
        await saveDraft()
    }

    /// The heavier revert: adopt a built-in's defaults while **keeping** this style's identity, so
    /// Save updates the same row rather than forking a differently-named copy beside the broken one.
    func revertToBuiltIn(_ template: LaTeXTemplateID) async {
        let descriptor = LaTeXTemplateRegistry.descriptor(for: template) ?? LaTeXTemplateRegistry.fallback
        stashedPreamble = draft.customPreamble
        let keptName = draftName
        draft = descriptor.defaultStyle          // its customPreamble is nil by construction
        draftName = keptName
        previewError = nil
        guard selectedStyleID != nil, canSaveStyle else { return }
        await saveDraft()
    }

    /// The sample `.tex` for the draft — how a user debugs a preamble that won't compile.
    func sampleTexSource() -> String? {
        exportApplication?.texSource(ExportApplicationUseCase.sampleKit, .resume, style: draft)
    }

    // MARK: Preview

    /// Compiles the bundled sample under the **draft** style. ~4s warm, ~8s on a machine whose
    /// font cache is cold, which is why this is a button rather than a live preview.
    func compilePreview() async {
        guard let exportApplication, canPreview else { return }
        isCompilingPreview = true
        previewError = nil
        defer { isCompilingPreview = false }
        do {
            previewPDF = try await exportApplication.previewPDF(style: draft)
        } catch {
            // The previous PDF deliberately stays on screen: comparing "what I had" with "what my
            // edit broke" is most of a preview's value when hand-writing LaTeX.
            previewError = ApplicationViewModel.describeExport(error, customPreamble: usesCustomPreamble)
        }
    }
}
