//
//  ApplicationWindow.swift
//  Taylor'd Portfolio
//
//  Presentation · App — the detached Application window (v0.5.0 Milestone B-C).
//

import SwiftUI

/// The detached window that generates / shows a job's tailored résumé + cover letter,
/// replacing the `.sheet(isPresented:)` formerly nested in `JobDetailView`. Reads the
/// target job + profile/grounding + start mode from the shared `AppSession` and builds a
/// fresh `ApplicationViewModel` from the `Composition`.
///
/// A single-instance `Window` (see `Taylor_d_PortfolioApp`); the session's request id lets
/// re-opening the same job (View → Regenerate) re-run even though the window persists.
struct ApplicationWindow: View {
    static let id = "application"

    let composition: Composition
    @Environment(AppSession.self) private var session
    @State private var application: ApplicationViewModel

    init(composition: Composition) {
        self.composition = composition
        _application = State(initialValue: composition.makeApplicationViewModel())
    }

    var body: some View {
        Group {
            if let job = session.applicationJob, let profile = session.profile {
                ApplicationSheet(
                    viewModel: application,
                    job: job,
                    profile: profile,
                    grounding: session.grounding,
                    startMode: session.applicationStartMode,
                    requestID: session.applicationRequestID,
                    onGenerated: { session.dataChanged() }
                )
            } else {
                ContentUnavailableView(
                    "No application",
                    systemImage: "doc.text",
                    description: Text("Open a saved job from the Tracker to generate its materials.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
