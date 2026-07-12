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
    let profile: CandidateProfile?
    let applicationViewModel: ApplicationViewModel
    var markStatus: MarkStatusUseCase? = nil
    var loadStatus: LoadStatusUseCase? = nil
    /// The candidate's real documents for grounded generation (Milestone T).
    var grounding: PortfolioGrounding? = nil
    /// Lets the detail view offer a "View" affordance when a generated kit already exists
    /// (v0.5.0 Milestone A).
    var loadApplication: LoadApplicationUseCase? = nil

    /// Opens the detached job-detail window (v0.5.0 Milestone B) instead of a sheet.
    @Environment(AppSession.self) private var session
    @Environment(\.openWindow) private var openWindow

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
                List(jobs) { tracked in
                    RankedRow(ranked: tracked.job, history: viewModel.history(for: tracked.job))
                        .contentShape(Rectangle())
                        .onTapGesture { openDetail(tracked.job) }
                        .clickableCursor()
                }
            }
        }
        .task { await viewModel.load() }
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
    return TrackerView(
        viewModel: vm,
        profile: Preview.sampleProfile,
        applicationViewModel: ApplicationViewModel(generateApplication: Preview.generateApplication)
    )
    .frame(width: 460, height: 400)
}
#endif
