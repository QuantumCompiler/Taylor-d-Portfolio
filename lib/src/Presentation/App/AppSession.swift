//
//  AppSession.swift
//  Taylor'd Portfolio
//
//  Presentation · App — shared state across scenes/windows (v0.5.0 Milestone B-A).
//

import Foundation
import Observation

/// Which context a job-detail window was opened from — drives the generate vs.
/// save-to-Tracker affordances in the detail view.
enum JobDetailContext: Sendable {
    case results
    case tracker
}

/// App-level session state shared by **every** scene, including detached windows.
///
/// A separate `Window` scene renders outside `RootView`'s view tree, so it can't read
/// `RootView`'s `@State`. This holds the live `profile` + `grounding` (which also can't
/// be passed as a `WindowGroup` value — `PortfolioGrounding` isn't `Codable`) and a
/// **revision token** that a detached window bumps whenever it mutates shared persistence
/// (mark status, generate, save), so the list screens in the main window can reload.
///
/// Injected once from `Taylor_d_PortfolioApp` via `.environment(_:)` so all scenes share
/// the same instance.
@MainActor
@Observable
final class AppSession {
    /// The currently-loaded profile (mirrored from `PortfolioViewModel` by `RootView`).
    var profile: CandidateProfile?
    /// The current grounding documents (résumé + optional cover letter) for generation.
    var grounding: PortfolioGrounding?

    /// The job whose **detail window** is open, and the context it was opened from.
    var detailJob: RankedJob?
    var detailContext: JobDetailContext = .tracker

    /// Bumped whenever a detached window mutates shared persistence, so the main window's
    /// Results / Tracker lists reload to reflect the change.
    private(set) var revision = 0

    /// Signals that shared persistence changed (status set, materials generated, job saved).
    func dataChanged() { revision &+= 1 }

    /// Opens (or re-targets) the detail window for `job` in the given `context`.
    func showDetail(_ job: RankedJob, context: JobDetailContext) {
        detailJob = job
        detailContext = context
    }
}
