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
            } else if jobs.isEmpty {
                ContentUnavailableView(
                    "No \(section.title.lowercased()) applications",
                    systemImage: "briefcase",
                    description: Text("Nothing at the \(section.title) stage yet — the All tab shows every tracked job.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    sortBar
                    List(jobs) { tracked in
                        trackerRow(tracked)
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
                .onTapGesture { openDetail(tracked.job) }
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
