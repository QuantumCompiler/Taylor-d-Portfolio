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

    /// The job whose **Application window** is open (v0.5.0 Milestone B-C), and a request id
    /// bumped on every open so the single-instance window reloads for a newly-opened job.
    var applicationJob: JobListing?
    private(set) var applicationRequestID = 0

    /// Bumped whenever a detached window mutates shared persistence, so the main window's
    /// Results / Tracker lists reload to reflect the change.
    private(set) var revision = 0

    /// The most-recently **regenerated** result (v0.6.0 Milestone C), set by a detached detail
    /// window. The Tracker reloads wholesale on `revision`, but the **Results** list holds
    /// unsaved in-memory search results (never re-read wholesale, per Milestone S-C), so it
    /// needs the refreshed job handed to it to replace just that row. Cleared once applied.
    var refreshedResult: RankedJob?

    /// Signals that shared persistence changed (status set, materials generated, job saved).
    func dataChanged() { revision &+= 1 }

    /// Opens (or re-targets) the detail window for `job` in the given `context`.
    func showDetail(_ job: RankedJob, context: JobDetailContext) {
        detailJob = job
        detailContext = context
    }

    /// Opens (or re-targets) the Application window for `job`.
    func showApplication(_ job: JobListing) {
        applicationJob = job
        applicationRequestID &+= 1
    }
}
