//
//  DocumentStylesView.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings · View — the document-style manager (v0.7.0 Milestone E).
//

import SwiftUI
import PDFKit

/// The **Document Styles** pane: the saved-style library plus an editor for the four control
/// groups, and a Preview that compiles a bundled sample under the draft style.
///
/// Its body is `Form`-legal *content* (sections, no `Form` of its own) because `SettingsView`
/// wraps every pane in one grouped `Form`.
///
/// **Every numeric control is bounded** (`Slider`/`Stepper` with a range), and that is deliberate:
/// `lualatex` exits 0 on absurd geometry — 1.6cm text width, twelve pages, negative margins — so
/// there is no compile error to catch a bad value and no banner to show. The bounded control *is*
/// the safety mechanism. Ranges are argued from measurements recorded in `MILESTONES.md`
/// (v0.7.0 E); values are never silently clamped, because `LaTeXStyle` deliberately doesn't.
struct DocumentStylesView: View {
    @Bindable var viewModel: DocumentStylesViewModel

    var body: some View {
        Group {
            librarySection
            // Everything an override writes into the preamble itself goes inert while one is
            // active — dimmed rather than hidden, so it's clear *why* it stopped mattering.
            templateSection.disabled(viewModel.usesCustomPreamble)
            typographySection.disabled(viewModel.usesCustomPreamble)
            colourSection.disabled(viewModel.usesCustomPreamble)
            geometrySection.disabled(viewModel.usesCustomPreamble)
            coverLetterSection
            sectionsSection
            advancedSection
            previewSection
        }
    }

    // MARK: Library

    private var librarySection: some View {
        Section {
            if !viewModel.supportsDocumentStyles {
                Text("Saving styles is unavailable in this build.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else if viewModel.savedStyles.isEmpty {
                Text("No saved styles yet. Edit the controls below and choose Save.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.savedStyles) { saved in
                    savedRow(saved)
                }
            }
        } header: {
            Text("Saved styles")
        } footer: {
            VStack(alignment: .leading, spacing: 12) {
                Text("A style themes the awesome-cv LaTeX export — the résumé and cover letter "
                    + "together. The PDF / Word exports keep their own template.")
                HStack {
                    TextField("Style name", text: $viewModel.draftName)
                        .frame(maxWidth: 240)
                    Button("Save") { Task { await viewModel.saveDraft() } }
                        .disabled(!viewModel.canSaveStyle)
                        .clickableCursor()
                    Menu("New from…") {
                        ForEach(viewModel.templates) { descriptor in
                            Button(descriptor.displayName) { viewModel.newStyle(from: descriptor.template) }
                        }
                    }
                    .fixedSize()
                    .clickableCursor()
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func savedRow(_ saved: SavedDocumentStyle) -> some View {
        HStack {
            Button {
                viewModel.select(saved)
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isDefault(saved) {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                    }
                    Text(saved.name)
                    if viewModel.selectedStyleID == saved.id {
                        Text("Editing").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .clickableCursor()

            Spacer()

            Button {
                viewModel.setDefault(saved)
            } label: {
                Image(systemName: viewModel.isDefault(saved) ? "star.fill" : "star")
            }
            .buttonStyle(.borderless)
            .help(viewModel.isDefault(saved) ? "Stop using this as the default"
                                             : "Use this style by default when exporting")
            .clickableCursor()

            Button {
                Task { await viewModel.duplicate(saved) }
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Duplicate this style")
            .clickableCursor()

            Button(role: .destructive) {
                Task { await viewModel.delete(saved) }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete this style")
            .clickableCursor()
        }
    }

    // MARK: Template

    private var templateSection: some View {
        Section("Template") {
            Picker("Base template", selection: $viewModel.draft.template) {
                ForEach(viewModel.templates) { descriptor in
                    Text(descriptor.displayName).tag(descriptor.template)
                }
            }
            if let descriptor = viewModel.templates.first(where: { $0.template == viewModel.draft.template }) {
                Text(descriptor.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Typography

    private var typographySection: some View {
        Section {
            Picker("Body font", selection: $viewModel.draft.fontFamily) {
                ForEach(LaTeXFontFamily.allCases) { family in
                    Text(family.displayName).tag(family)
                }
            }
            // A discrete picker, not a free field: the awesome-cv classes size every element
            // absolutely, and `article` honours only 10/11/12pt — anything else is silently the
            // same as 10pt. A numeric field would promise control the classes can't deliver.
            Picker("Résumé base size", selection: $viewModel.draft.fontSizes.resumePt) {
                Text("Template default").tag(LaTeXFontSizes.default.resumePt)
                ForEach([10.0, 11.0, 12.0], id: \.self) { size in
                    Text("\(Int(size)) pt").tag(size)
                }
            }
            Picker("Cover letter base size", selection: $viewModel.draft.fontSizes.coverLetterPt) {
                ForEach([10.0, 11.0, 12.0], id: \.self) { size in
                    Text("\(Int(size)) pt").tag(size)
                }
            }
        } header: {
            Text("Typography")
        } footer: {
            Text("Base size scales the documents' vertical spacing; the classes set text sizes "
                + "themselves, so it isn't a text-size control.")
        }
    }

    // MARK: Accent colour

    private var colourSection: some View {
        Section("Accent colour") {
            Picker("Accent", selection: accentSelection) {
                Text("Template default").tag(LaTeXAwesomeColor?.none)
                ForEach(LaTeXAwesomeColor.allCases) { colour in
                    Text(colour.displayName).tag(LaTeXAwesomeColor?.some(colour))
                }
            }
        }
    }

    /// The palette picker binds through `LaTeXAccent`'s cases. A custom hex stays representable in
    /// the model (and survives a round-trip) but isn't offered here — the palette is what the
    /// bundled classes define.
    private var accentSelection: Binding<LaTeXAwesomeColor?> {
        Binding(
            get: {
                if case let .named(colour) = viewModel.draft.accent { return colour }
                return nil
            },
            set: { viewModel.draft.accent = $0.map(LaTeXAccent.named) ?? .templateDefault }
        )
    }

    // MARK: Geometry + page size

    private var geometrySection: some View {
        Section {
            Picker("Page size", selection: $viewModel.draft.pageSize) {
                ForEach(LaTeXPageSize.allCases) { size in
                    Text(size.displayName).tag(size)
                }
            }
            marginStepper("Left margin", value: $viewModel.draft.margins.leftCm)
            marginStepper("Right margin", value: $viewModel.draft.margins.rightCm)
            marginStepper("Top margin", value: $viewModel.draft.margins.topCm)
            marginStepper("Bottom margin", value: $viewModel.draft.margins.bottomCm)
            marginStepper("Footer skip", value: $viewModel.draft.margins.footskipCm, range: 0...2)
        } header: {
            Text("Page & margins")
        } footer: {
            Text("Margins are bounded so an entry row always fits: the classes reserve a fixed "
                + "6 cm column for dates and locations.")
        }
    }

    /// The letter's body spacing is **not** part of the preamble — it's emitted after
    /// `\begin{document}`, so a custom preamble doesn't disable it. Hence its own section, rather
    /// than sitting under "Page & margins" which an override does make inert.
    private var coverLetterSection: some View {
        Section("Cover letter") {
            Stepper(value: $viewModel.draft.letterParagraphSkipEm, in: 0...3, step: 0.1) {
                Text("Paragraph gap: \(viewModel.draft.letterParagraphSkipEm, specifier: "%.1f") em")
            }
            Stepper(value: $viewModel.draft.letterLineSpread, in: 0.8...2, step: 0.01) {
                Text("Line spacing: \(viewModel.draft.letterLineSpread, specifier: "%.2f")")
            }
        }
    }

    private func marginStepper(_ label: String, value: Binding<Double>,
                               range: ClosedRange<Double> = 0...4) -> some View {
        Stepper(value: value, in: range, step: 0.05) {
            Text("\(label): \(value.wrappedValue, specifier: "%.2f") cm")
        }
    }

    // MARK: Section order & visibility

    private var sectionsSection: some View {
        Section {
            ForEach(viewModel.draft.sectionOrder, id: \.self) { section in
                sectionRow(section)
            }
        } header: {
            Text("Sections")
        } footer: {
            Text("Order, show/hide and space each part of the résumé. Sections the app doesn't "
                + "recognise fall under \"Other sections\" and always print last. Spacing is "
                + "negative to tighten; below −1.0 em a heading starts to touch the summary above it.")
        }
    }

    private func sectionRow(_ section: LaTeXResumeSection) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(isOn: Binding(
                    get: { viewModel.isVisible(section) },
                    set: { viewModel.setVisible(section, $0) }
                )) {
                    Text(section.displayName)
                }
                .toggleStyle(.checkbox)

                Spacer()

                Button {
                    viewModel.moveSection(section, by: -1)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.draft.sectionOrder.first == section)
                .help("Move earlier")
                .clickableCursor()

                Button {
                    viewModel.moveSection(section, by: 1)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.draft.sectionOrder.last == section)
                .help("Move later")
                .clickableCursor()
            }
            Stepper(value: Binding(
                get: { viewModel.spacing(for: section) },
                set: { viewModel.setSpacing($0, for: section) }
            ), in: -1.5...3, step: 0.1) {
                Text("Space before: \(viewModel.spacing(for: section), specifier: "%.1f") em")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Advanced — the raw-LaTeX escape hatch (v0.7.0 Milestone F)

    private var advancedSection: some View {
        Section {
            Toggle("Replace the generated preamble with my own LaTeX", isOn: overrideBinding)
                .toggleStyle(.checkbox)

            // Conditional rendering, not `.disabled` — a disabled TextEditor still accepts typing
            // on macOS 26, so the gate has to remove it rather than grey it.
            if viewModel.usesCustomPreamble {
                Text("Your LaTeX replaces the \u{5C}geometry line, the body-font override and the "
                    + "accent override. The app still writes \u{5C}documentclass (it differs per "
                    + "document, so don't write your own), \u{5C}nonstopmode, \u{5C}fontdir, "
                    + "\u{5C}pageHeader, your headline's \u{5C}position, \u{5C}pageFooter, and the "
                    + "\u{5C}cventrysolo / \u{5C}cvprojectsolo definitions the generated body calls.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Still applies: page size, base size, section order/visibility/spacing, and "
                    + "the cover letter's spacing. No longer applies: margins, body font, accent. "
                    + "To use your own name, \u{5C}renewcommand{\u{5C}pageHeader}{\u{5C}name{First}{Last}…}.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                TextEditor(text: $viewModel.customPreambleText)
                    .font(.body.monospaced())
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200, maxHeight: 380)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    .accessibilityLabel("Raw LaTeX preamble")

                if viewModel.customPreambleIsBlank {
                    Text("Empty — the generated preamble will be used.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Button("Start from the generated preamble") { viewModel.resetPreambleToGenerated() }
                        .clickableCursor()
                    Button("Use the generated preamble") { Task { await viewModel.dropCustomPreamble() } }
                        .clickableCursor()
                    Menu("Revert to a built-in…") {
                        ForEach(viewModel.templates) { descriptor in
                            Button(descriptor.displayName) {
                                Task { await viewModel.revertToBuiltIn(descriptor.template) }
                            }
                        }
                    }
                    .fixedSize()
                    .clickableCursor()
                }
            }
        } header: {
            Text("Advanced")
        } footer: {
            Text("This is raw LaTeX, not a theme: a preamble can add or suppress typeset content "
                + "and read files you can read. It can't run shell commands. Check the Preview "
                + "before you export — and note the .tex source export keeps working even when a "
                + "preamble won't compile, which is how you debug one.")
        }
    }

    private var overrideBinding: Binding<Bool> {
        Binding(get: { viewModel.usesCustomPreamble },
                set: { viewModel.setUsesCustomPreamble($0) })
    }

    // MARK: Preview

    private var previewSection: some View {
        Section {
            HStack(spacing: 10) {
                Button("Preview") { Task { await viewModel.compilePreview() } }
                    .disabled(!viewModel.canPreview || viewModel.isCompilingPreview)
                    .help(viewModel.canPreview
                          ? "Compile a sample résumé in this style"
                          : "LaTeX output: install a TeX distribution (MacTeX) to enable the "
                            + "awesome-cv PDF export")
                    .clickableCursor()
                if viewModel.isCompilingPreview {
                    ProgressView().controlSize(.small)
                    Text("Compiling with lualatex…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let previewError = viewModel.previewError {
                ScrollView(.vertical) {
                    Text(previewError)
                        .font(.callout.monospaced())
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 160)
            }
            if let image = previewImage {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .border(Color.secondary.opacity(0.3))
                    .accessibilityLabel("Sample résumé rendered in this style")
            }
        } header: {
            Text("Preview")
        } footer: {
            Text("Compiles a sample résumé — a few seconds, and longer the first time while the "
                + "font cache builds. A preview isn't live because each compile costs that much.")
        }
    }

    /// Page 1 of the compiled sample. One page is all a style preview needs, and a thumbnail
    /// avoids pulling a `PDFView` wrapper into the app for it.
    private var previewImage: Image? {
        guard let data = viewModel.previewPDF,
              let page = PDFDocument(data: data)?.page(at: 0)
        else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        return Image(nsImage: page.thumbnail(of: bounds.size, for: .mediaBox))
    }
}
