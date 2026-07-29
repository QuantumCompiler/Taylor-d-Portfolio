//
//  TrackerView.swift
//  Taylor'd Portfolio
//
//  Presentation · Tracker · View
//

import SwiftUI

/// Lists the jobs the user is tracking (has marked with a status). Tapping one opens
/// its detail view, where the status can be advanced.
struct TrackerView: View {
    @Bindable var viewModel: TrackerViewModel
    /// Which stage-filtered sub-view to show (v0.4.0 Milestone B). Defaults to `all`, so
    /// `#Preview`s and any direct callers keep their prior "everything" behaviour.
    var section: TrackerSection = .all

    /// Opens the detached job-detail window (v0.5.0 Milestone B) instead of a sheet.
    @Environment(AppSession.self) private var session
    @Environment(\.openWindow) private var openWindow

    /// The job awaiting delete confirmation (v0.6.2 Milestone A). Every delete path — row
    /// icon, context menu, swipe — routes through here, so the destructive action is
    /// confirmed once, consistently, wherever it was triggered from.
    @State private var pendingDelete: RankedJob?
    /// Whether the **bulk** delete is awaiting confirmation (v0.6.2 Milestone B) — separate
    /// from `pendingDelete`, since it names a count rather than one job.
    @State private var confirmingBulkDelete = false

    /// The tracked jobs shown for the selected stage filter.
    private var jobs: [TrackedJob] { viewModel.jobs(in: section) }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isEmpty {
                // Stretch so the empty state centers in the pane (matches the ProgressView
                // branch), rather than hugging the top under the tabs (v0.4.1 Milestone E).
                ContentUnavailableView(
                    "No tracked applications",
                    systemImage: "briefcase",
                    description: Text("Save a job from the Results area (the bookmark icon, or swipe a result right) to track it here, then generate its résumé & cover letter.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.totalCount(in: section) == 0 {
                // The *stage* is empty — distinct from "a filter hid this tab's rows", which
                // keeps the bars visible below so the filter can be cleared (v0.6.2 C).
                ContentUnavailableView(
                    "No \(section.title.lowercased()) applications",
                    systemImage: "briefcase",
                    description: Text("Nothing at the \(section.title) stage yet — the All tab shows every tracked job.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    filterBar
                    sortBar
                    if viewModel.hasSelection(in: section) { bulkActionBar }
                    if viewModel.isFilteredEmpty(in: section) {
                        ContentUnavailableView {
                            Label("No tracked applications match your filters", systemImage: "line.3.horizontal.decrease.circle")
                        } description: {
                            Text("Clear or loosen your filters to see this stage's applications.")
                        } actions: {
                            Button("Clear filters") { viewModel.clearFilter() }.clickableCursor()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(jobs, selection: $viewModel.selectedIDs) { tracked in
                            trackerRow(tracked)
                        }
                    }
                }
            }
        }
        .task { await viewModel.load() }
        .confirmationDialog(
            "Delete this tracked application?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            presenting: pendingDelete
        ) { job in
            Button("Delete", role: .destructive) { remove(job) }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { job in
            Text("“\(job.listing.title)” at \(job.listing.company) will be forgotten — the saved listing, its application status, and any generated résumé & cover letter. This can't be undone.\n\nTo keep the job and just take it off the Tracker, use “Return to Results” instead.")
        }
        .confirmationDialog(
            "Delete \(viewModel.selectionCount(in: section)) tracked \(viewModel.selectionCount(in: section) == 1 ? "application" : "applications")?",
            isPresented: $confirmingBulkDelete
        ) {
            Button("Delete \(viewModel.selectionCount(in: section))", role: .destructive) {
                Task { await viewModel.deleteSelected(in: section); session.dataChanged() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("They'll be forgotten — the saved listings, their application statuses, and any generated résumés & cover letters. This can't be undone.\n\nTo keep them and just take them off the Tracker, use “Return to Results” instead.")
        }
    }

    /// The shared `ListFilterBar` — the same control Results uses (v0.6.2 Milestone C), scoped
    /// to the selected stage tab. The `trackedStatus` facet stays hidden: everything here is
    /// tracked, and the stage tabs already segment by stage.
    private var filterBar: some View {
        ListFilterBar(
            filter: $viewModel.filter,
            locationOptions: viewModel.locationOptions(in: section),
            companyOptions: viewModel.companyOptions(in: section),
            visibleCount: viewModel.visibleCount(in: section),
            totalCount: viewModel.totalCount(in: section),
            onClear: { viewModel.clearFilter() }
        )
    }

    /// Appears only while rows are selected (v0.6.2 Milestone B): the same two removals the
    /// rows offer, applied to the whole selection. Delete confirms with a count; Return to
    /// Results doesn't (nothing is lost).
    private var bulkActionBar: some View {
        HStack(spacing: 12) {
            Text("\(viewModel.selectionCount(in: section)) selected")
                .font(.callout).monospacedDigit()

            if viewModel.supportsRowActions {
                Button {
                    Task { await viewModel.returnSelectedToResults(in: section); session.dataChanged() }
                } label: {
                    Label("Return to Results", systemImage: "arrow.uturn.backward")
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

    /// A compact, live sort control above the list (Milestone H) — the Tracker analogue of the
    /// Results filter bar. Reorders the shown rows without reloading; only appears when there
    /// are rows to sort. A "Reset" restores the default (most-recent-activity) order.
    @ViewBuilder
    private var sortBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.arrow.down").font(.caption).foregroundStyle(.secondary)
            Picker("Sort", selection: $viewModel.sort.key) {
                ForEach(TrackerSort.Key.allCases) { key in
                    Text(key.displayName).tag(key)
                }
            }
            .labelsHidden()
            .fixedSize()
            .help("Sort the tracked applications")

            Button {
                viewModel.sort.direction = viewModel.sort.direction == .ascending ? .descending : .ascending
            } label: {
                Image(systemName: viewModel.sort.direction == .ascending ? "arrow.up" : "arrow.down")
            }
            .buttonStyle(.borderless)
            .help(viewModel.sort.direction.displayName)
            .clickableCursor()

            if !viewModel.sort.isDefault {
                Button("Reset") { viewModel.sort = .default }
                    .buttonStyle(.borderless)
                    .clickableCursor()
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    /// One tracked-job row. Both removals are reachable three ways (v0.6.2 Milestone A):
    /// **visible row icons** (mirroring the Results tab, so the two list tabs match),
    /// a right-click **context menu** (the native macOS pattern), and the original
    /// **swipes** — leading/right = back to Results, trailing/left = delete. The swipe-only
    /// affordance shipped in v0.5.0 was undiscoverable on macOS; the behaviour is unchanged,
    /// only how you find it. Delete keeps `allowsFullSwipe: false` and now also confirms,
    /// since it removes the listing + status + materials. Every path signals the shared
    /// session so Results updates.
    @ViewBuilder
    private func trackerRow(_ tracked: TrackedJob) -> some View {
        let row = HStack(spacing: 8) {
            RankedRow(ranked: tracked.job, history: viewModel.history(for: tracked.job))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                // Double-click opens the detail; single click belongs to the List's multi-select
                // (v0.6.2 Milestone B), same as Results.
                .simultaneousGesture(TapGesture(count: 2).onEnded { openDetail(tracked.job) })
                .help("Double-click to open · ⌘-click or shift-click to select several")
                .clickableCursor()
            if viewModel.supportsRowActions {
                rowActions(tracked.job)
            }
        }
        if viewModel.supportsRowActions {
            row
                .contextMenu { rowMenu(tracked.job) }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button { returnToResults(tracked.job) } label: {
                        Label("To Results", systemImage: "arrow.uturn.backward")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { pendingDelete = tracked.job } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        } else {
            row
        }
    }

    /// Always-visible per-row icons, matching the Results tab's save/delete pair so the two
    /// list tabs feel the same. Each intercepts its own tap (the row tap opens the detail).
    private func rowActions(_ job: RankedJob) -> some View {
        HStack(spacing: 10) {
            Button { returnToResults(job) } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.plain).foregroundStyle(.tint)
            .help("Return to Results — keeps the job, just clears its status")
            .clickableCursor()

            Button(role: .destructive) { pendingDelete = job } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain).foregroundStyle(.secondary)
            .help("Delete — forgets the listing, its status, and any generated materials")
            .clickableCursor()
        }
    }

    /// The right-click menu — the same two actions, in the pattern Mac users reach for first.
    @ViewBuilder
    private func rowMenu(_ job: RankedJob) -> some View {
        Button { returnToResults(job) } label: {
            Label("Return to Results", systemImage: "arrow.uturn.backward")
        }
        Divider()
        Button(role: .destructive) { pendingDelete = job } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: Actions

    /// Clears the job's status so it returns to Results. Non-destructive (the listing and any
    /// generated materials are kept), so it isn't confirmed.
    private func returnToResults(_ job: RankedJob) {
        Task { await viewModel.returnToResults(job); session.dataChanged() }
    }

    /// Performs the confirmed delete and clears the pending job.
    private func remove(_ job: RankedJob) {
        pendingDelete = nil
        Task { await viewModel.delete(job); session.dataChanged() }
    }

    /// Opens the shared detail window for `ranked` in the Tracker context. The window reloads
    /// this list via the session revision signal when it mutates status/materials.
    private func openDetail(_ ranked: RankedJob) {
        session.showDetail(ranked, context: .tracker)
        openWindow(id: JobDetailWindow.id)
    }
}

#if DEBUG
#Preview {
    let vm = TrackerViewModel()
    return TrackerView(viewModel: vm)
        .frame(width: 460, height: 400)
}
#endif
