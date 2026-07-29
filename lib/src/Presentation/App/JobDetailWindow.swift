//
//  JobDetailWindow.swift
//  Taylor'd Portfolio
//
//  Presentation · App — the detached job-detail window (v0.5.0 Milestone B-B).
//

import SwiftUI

/// The detached window that shows one job's detail, replacing the former `.sheet(item:)`
/// in Results and the Tracker. Reads the selected job + profile/grounding from the shared
/// `AppSession`, and builds the detail view's dependencies from the `Composition`.
///
/// A single-instance `Window` (see `Taylor_d_PortfolioApp`): opening a different job
/// re-targets `session.detailJob`, and the window's content updates reactively.
struct JobDetailWindow: View {
    static let id = "job-detail"

    let composition: Composition
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if let ranked = session.detailJob {
                JobDetailView(
                    ranked: ranked,
                    profile: session.profile,
                    markStatus: composition.markStatus,
                    loadStatus: composition.loadStatus,
                    grounding: session.grounding,
                    canGenerate: session.detailContext == .tracker,
                    onSaveToTracker: session.detailContext == .results ? { saveToTracker(ranked) } : nil,
                    loadApplication: composition.loadApplication,
                    onReturnToResults: canRemove ? { returnToResults(ranked) } : nil,
                    onDelete: canRemove ? { delete(ranked) } : nil,
                    allowsSwipe: false,
                    regenerateResult: composition.regenerateResult,
                    loadProfiles: composition.loadProfiles,
                    onMutate: { session.dataChanged() },
                    onRegenerated: { session.refreshedResult = $0 },
                    onOpenApplication: {
                        session.showApplication(ranked.listing)
                        openWindow(id: ApplicationWindow.id)
                    },
                    onSelectProfile: { saved in
                        // Picking a profile in the detail loads it session-wide, so generation
                        // works from here (Generate enables) without a Portfolio-tab detour.
                        session.profile = saved.profile
                        session.grounding = saved.grounding
                    },
                    refreshSignal: session.revision
                )
                // This is a single-instance window reused for every job. Key the detail view by
                // the job id so opening a different result gives it a **fresh** identity — its
                // per-job `@State` (status, generated-materials flag, and the regenerate-result
                // holder `displayRanked`) resets and `.task` re-runs. Without this the window
                // keeps showing the first/regenerated job no matter which row was clicked.
                .id(ranked.id)
            } else {
                ContentUnavailableView("No job selected", systemImage: "doc.text")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// Whether the detail can offer the remove actions: the **Tracker** context (a Results job
    /// isn't tracked yet), and only when persistence wired both use cases — mirroring
    /// `TrackerViewModel.supportsRowActions` (v0.6.2 Milestone A).
    private var canRemove: Bool {
        session.detailContext == .tracker && composition.untrackJob != nil && composition.deleteSavedJob != nil
    }

    /// Tracker context: clear the job's status so it returns to Results, keeping the listing
    /// and any generated materials. The detail view dismisses itself after calling this.
    private func returnToResults(_ ranked: RankedJob) {
        guard let untrackJob = composition.untrackJob else { return }
        Task {
            try? await untrackJob(jobID: ranked.id)
            session.dataChanged()
        }
    }

    /// Tracker context: forget the job entirely (listing + status + materials). Confirmed in
    /// the detail view before it calls this.
    private func delete(_ ranked: RankedJob) {
        guard let deleteSavedJob = composition.deleteSavedJob else { return }
        Task {
            try? await deleteSavedJob(jobID: ranked.id)
            session.dataChanged()
        }
    }

    /// Results context: mark the job `.saved` (moving it into the Tracker), signal the
    /// change so the lists reload, and close the window.
    private func saveToTracker(_ ranked: RankedJob) {
        if let markStatus = composition.markStatus {
            Task {
                _ = try? await markStatus(jobID: ranked.id, stage: .saved)
                session.dataChanged()
            }
        }
        dismiss()
    }
}
