//
//  UntrackJobUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — remove a job from the Tracker without deleting it (v0.5.0).
//

import Foundation

/// Removes a job from the Tracker **without forgetting it**: clears only its
/// ``ApplicationStatus`` so the job returns to Results as an un-triaged result. The saved
/// listing and any generated materials are kept, so the move is reversible (re-saving to
/// the Tracker brings its materials back).
///
/// Contrast with ``DeleteSavedJobUseCase``, which forgets the listing, status, and
/// materials together.
nonisolated struct UntrackJobUseCase: Sendable {
    let statuses: SavedStatusRepository

    init(statuses: SavedStatusRepository) {
        self.statuses = statuses
    }

    func callAsFunction(jobID: String) async throws {
        try await statuses.delete(jobID: jobID)
    }
}
