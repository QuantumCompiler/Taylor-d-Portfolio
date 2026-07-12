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
                    allowsSwipe: false,
                    onMutate: { session.dataChanged() },
                    onOpenApplication: {
                        session.showApplication(ranked.listing)
                        openWindow(id: ApplicationWindow.id)
                    },
                    refreshSignal: session.revision
                )
            } else {
                ContentUnavailableView("No job selected", systemImage: "doc.text")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
