//
//  App.swift
//  Taylor'd Portfolio
//
//  Presentation · App — the composition root.
//

import SwiftUI

/// Entry point and composition root for Taylor'd Portfolio.
///
/// This is the one place allowed to reference every layer and wire them together
/// (Infrastructure → Data → Business → ViewModels). It opens straight to the main
/// tabs, starting on the Portfolio tab.
@main
struct Taylor_d_PortfolioApp: App {
    private let composition = Composition()
    /// Shared across every scene so the detached windows (v0.5.0 Milestone B) can read the
    /// live profile/grounding and signal list reloads.
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView(composition: composition)
                .frame(minWidth: 800, minHeight: 500)
                .environment(session)
        }
        .defaultSize(width: 800, height: 500)
        .windowResizability(.contentMinSize)

        // The detached job-detail window (v0.5.0 Milestone B-B). Single-instance: opening a
        // different job re-targets `session.detailJob` and this window updates reactively.
        Window("Job Detail", id: JobDetailWindow.id) {
            JobDetailWindow(composition: composition)
                .frame(minWidth: 540, minHeight: 500)
                .environment(session)
        }
        .defaultSize(width: 620, height: 680)
        .windowResizability(.contentMinSize)
    }
}
