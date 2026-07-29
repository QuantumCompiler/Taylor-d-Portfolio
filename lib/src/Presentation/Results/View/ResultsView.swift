//
//  ResultsView.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · View
//

import SwiftUI

/// The ranked results list. Tapping a job opens its detail view (from which the user
/// can read the full posting, generate an application, and set its status).
struct ResultsView: View {
    @Bindable var viewModel: ResultsViewModel

    /// Opens the detached job-detail window (v0.5.0 Milestone B) instead of a sheet.
    @Environment(AppSession.self) private var session
    @Environment(\.openWindow) private var openWindow
    @State private var showFilters = false
    /// Whether the bulk delete is awaiting confirmation (v0.6.2 Milestone B) — it forgets
    /// several listings + statuses + materials at once, so it confirms with a count.
    @State private var confirmingBulkDelete = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isEmpty {
                // Centered in the pane (matches the loading branch) — v0.4.1 Milestone E.
                ContentUnavailableView(
                    "No results yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Run a search to see jobs ranked against your profile.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.allResultsTracked {
                // Loaded results, but every one has been saved to the Tracker (Milestone C).
                ContentUnavailableView(
                    "All results are in your Tracker",
                    systemImage: "briefcase",
                    description: Text("Every ranked job has been saved to the Tracker. Run a new search to see more.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    filterBar
                    if viewModel.isFilteredEmpty {
                        ContentUnavailableView {
                            Label("No results match your filters", systemImage: "line.3.horizontal.decrease.circle")
                        } description: {
                            Text("Clear or loosen your filters to see the ranked results.")
                        } actions: {
                            Button("Clear filters") { viewModel.clearFilter() }.clickableCursor()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)   // center below the filter bar (v0.4.1 Milestone E)
                    } else {
                        if viewModel.hasSelection { bulkActionBar }
                        List(viewModel.filteredResults, selection: $viewModel.selectedIDs) { ranked in
                            resultRow(ranked)
                        }
                    }
                }
            }
        }
        .task { await viewModel.loadSavedIfNeeded() }
        .confirmationDialog(
            "Delete \(viewModel.selectionCount) \(viewModel.selectionCount == 1 ? "result" : "results")?",
            isPresented: $confirmingBulkDelete
        ) {
            Button("Delete \(viewModel.selectionCount)", role: .destructive) {
                Task { await viewModel.deleteSelected() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("They'll be forgotten — the saved listings, any application status, and any generated résumé & cover letter. This can't be undone.")
        }
    }

    // MARK: Bulk actions (v0.6.2 Milestone B)

    /// Appears only while rows are selected: what's selected, and the two bulk actions over it.
    /// Delete confirms with a count; Save doesn't (it's reversible from the Tracker).
    private var bulkActionBar: some View {
        HStack(spacing: 12) {
            Text("\(viewModel.selectionCount) selected")
                .font(.callout).monospacedDigit()

            if viewModel.supportsBulkActions {
                Button {
                    Task { await viewModel.saveSelectedToTracker() }
                } label: {
                    Label("Save to Tracker", systemImage: "bookmark")
                }
                .clickableCursor()

                Button(role: .destructive) {
                    confirmingBulkDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .clickableCursor()
            }

            Spacer()
            if viewModel.isBulkActing { ProgressView().controlSize(.small) }
            Button("Clear") { viewModel.clearSelection() }
                .buttonStyle(.borderless)
                .clickableCursor()
        }
        .disabled(viewModel.isBulkActing)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.selection.opacity(0.15))
    }

    /// Opens the shared detail window for `ranked` in the Results context (read + save, no
    /// generation — Milestone V-D). The window signals a reload when it saves to the Tracker.
    private func openDetail(_ ranked: RankedJob) {
        session.showDetail(ranked, context: .results)
        openWindow(id: JobDetailWindow.id)
    }

    // MARK: Filter bar (Milestone W)

    private var filterBar: some View {
        DisclosureGroup(isExpanded: $showFilters) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Minimum rank").frame(width: 120, alignment: .leading).foregroundStyle(.secondary)
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.filter.minScore ?? 0) },
                            set: { viewModel.filter.minScore = $0 >= 1 ? Int($0) : nil }
                        ),
                        in: 0...100, step: 5
                    ).frame(maxWidth: 200).clickableCursor()
                    Text(viewModel.filter.minScore.map { "\($0)+" } ?? "Any").monospacedDigit()
                }
                filterField("Keywords") {
                    TextField("Any", text: $viewModel.filter.keywords).textFieldStyle(.roundedBorder).frame(maxWidth: 220)
                }
                filterField("Location") {
                    optionPicker(selection: $viewModel.filter.location, options: viewModel.locationOptions)
                }
                filterField("Company") {
                    optionPicker(selection: $viewModel.filter.company, options: viewModel.companyOptions)
                }
                filterField("Min salary") {
                    TextField("Any", text: Binding(
                        get: { viewModel.filter.salaryMin.map { String(Int($0)) } ?? "" },
                        set: { viewModel.filter.salaryMin = Double($0.filter(\.isNumber)) }
                    )).textFieldStyle(.roundedBorder).frame(maxWidth: 140)
                }
                // (No "Tracked" filter — tracked jobs no longer appear in Results; they live
                //  in the Tracker as of v0.4.1 Milestone C.)
            }
            .padding(.top, 6)
        } label: {
            HStack {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                Spacer()
                Text("Showing \(viewModel.visibleCount) of \(viewModel.totalCount)")
                    .font(.caption).foregroundStyle(.secondary)
                if viewModel.filter.isActive {
                    Button("Clear") { viewModel.clearFilter() }.font(.caption).clickableCursor()
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private func filterField<Controls: View>(_ label: String, @ViewBuilder controls: () -> Controls) -> some View {
        HStack(spacing: 8) {
            Text(label).frame(width: 120, alignment: .leading).foregroundStyle(.secondary)
            controls()
            Spacer(minLength: 0)
        }
    }

    /// A picker over `options` (plus "Any") bound to an optional string.
    private func optionPicker(selection: Binding<String?>, options: [String]) -> some View {
        Picker("", selection: Binding(
            get: { selection.wrappedValue ?? "" },
            set: { selection.wrappedValue = $0.isEmpty ? nil : $0 }
        )) {
            Text("Any").tag("")
            ForEach(options, id: \.self) { Text($0).tag($0) }
        }
        .labelsHidden().fixedSize().clickableCursor()
    }

    /// Per-row Save-to-Tracker + Delete icons (Milestone V-A/V-B); each intercepts its own tap.
    /// One result row: the ranked card + explicit save/delete icons, plus **swipe-to-save**
    /// (leading / swipe right) and **swipe-to-delete** (trailing / swipe left) — restored after
    /// the detail moved to a window (v0.5.0). Both reuse the same view-model methods as the icons.
    /// Delete uses `allowsFullSwipe: false` (reveal + tap) since it also clears saved status +
    /// materials; save is a safe full-swipe.
    ///
    /// **Opening the detail is a double-click** as of v0.6.2 Milestone B: the enclosing `List`
    /// now owns single-click for multi-select (⌘/shift-click extend), so the former
    /// single-`onTapGesture` would have swallowed every selection. A `simultaneousGesture`
    /// (rather than `onTapGesture(count: 2)`) keeps the single click reaching the List.
    @ViewBuilder
    private func resultRow(_ ranked: RankedJob) -> some View {
        let row = HStack(spacing: 8) {
            RankedRow(ranked: ranked, history: viewModel.history(for: ranked))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture(count: 2).onEnded { openDetail(ranked) })
                .help("Double-click to open · ⌘-click or shift-click to select several")
                .clickableCursor()
            if viewModel.supportsRowActions {
                rowActions(ranked)
            }
        }
        if viewModel.supportsRowActions {
            row
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button { Task { await viewModel.saveToTracker(ranked) } } label: {
                        Label(viewModel.isTracked(ranked) ? "Saved" : "Save", systemImage: "bookmark.fill")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { Task { await viewModel.delete(ranked) } } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        } else {
            row
        }
    }

    private func rowActions(_ ranked: RankedJob) -> some View {
        HStack(spacing: 10) {
            Button { Task { await viewModel.saveToTracker(ranked) } } label: {
                Image(systemName: viewModel.isTracked(ranked) ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.plain).foregroundStyle(.tint)
            .help(viewModel.isTracked(ranked) ? "Saved to Tracker" : "Save to Tracker")
            .clickableCursor()

            Button(role: .destructive) { Task { await viewModel.delete(ranked) } } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain).foregroundStyle(.secondary)
            .help("Delete — removes it and any saved status/materials")
            .clickableCursor()
        }
    }
}

#if DEBUG
#Preview {
    ResultsView(viewModel: ResultsViewModel(results: Preview.sampleRankedJobs))
        .frame(width: 460, height: 400)
}
#endif
