//
//  TrackedJob.swift
//  Taylor'd Portfolio
//
//  Data · Models — a saved job paired with its application status.
//

import Foundation

/// A saved ``RankedJob`` paired with its ``ApplicationStatus`` — the unit the Tracker
/// screen lists. Identity is the underlying listing's id.
nonisolated struct TrackedJob: Identifiable, Equatable, Sendable {
    var job: RankedJob
    var status: ApplicationStatus

    var id: String { job.id }

    init(job: RankedJob, status: ApplicationStatus) {
        self.job = job
        self.status = status
    }
}
