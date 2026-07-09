//
//  ApplicationStatus.swift
//  Taylor'd Portfolio
//
//  Data · Models — where an application stands, with auto-stamped dates.
//

import Foundation

/// The stage an application is at. Ordered roughly by progression; the terminal
/// outcomes all stamp `closedDate`.
nonisolated enum ApplicationStage: String, Codable, CaseIterable, Sendable {
    case saved
    case applied
    case interviewing
    case offer
    case accepted
    case declined
    case rejected
    case withdrawn

    /// Human-readable label for badges and menus.
    var label: String {
        switch self {
        case .saved: "Saved"
        case .applied: "Applied"
        case .interviewing: "Interviewing"
        case .offer: "Offer"
        case .accepted: "Accepted"
        case .declined: "Declined"
        case .rejected: "Rejected"
        case .withdrawn: "Withdrawn"
        }
    }

    /// The stages a user can explicitly set (everything except the implicit `saved`).
    static var settable: [ApplicationStage] { allCases.filter { $0 != .saved } }

    /// Whether this is a terminal outcome (stamps `closedDate`).
    var isClosed: Bool {
        switch self {
        case .accepted, .declined, .rejected, .withdrawn: true
        default: false
        }
    }
}

/// Where a job application stands: the current ``ApplicationStage`` plus the dates the
/// key transitions were stamped. Dates are stamped **automatically** on transition —
/// the user never types one. `Codable`/`Equatable`/`Sendable` like the other models.
nonisolated struct ApplicationStatus: Codable, Equatable, Sendable {
    var stage: ApplicationStage
    var appliedDate: Date?
    var interviewDate: Date?
    var offerDate: Date?
    /// Set when a terminal outcome (accepted/declined/rejected/withdrawn) is reached.
    var closedDate: Date?
    var note: String

    init(
        stage: ApplicationStage = .saved,
        appliedDate: Date? = nil,
        interviewDate: Date? = nil,
        offerDate: Date? = nil,
        closedDate: Date? = nil,
        note: String = ""
    ) {
        self.stage = stage
        self.appliedDate = appliedDate
        self.interviewDate = interviewDate
        self.offerDate = offerDate
        self.closedDate = closedDate
        self.note = note
    }

    /// Returns a copy advanced to `newStage`, auto-stamping the corresponding milestone
    /// at `date`. Forward milestones (applied/interview/offer) stamp only if not already
    /// set — the date reflects when the stage was *first* reached; the terminal
    /// `closedDate` always reflects the latest outcome. Pure, so it's unit-tested.
    func advanced(to newStage: ApplicationStage, on date: Date) -> ApplicationStatus {
        var copy = self
        copy.stage = newStage
        switch newStage {
        case .saved:
            break
        case .applied:
            if copy.appliedDate == nil { copy.appliedDate = date }
        case .interviewing:
            if copy.interviewDate == nil { copy.interviewDate = date }
        case .offer:
            if copy.offerDate == nil { copy.offerDate = date }
        case .accepted, .declined, .rejected, .withdrawn:
            copy.closedDate = date
        }
        return copy
    }

    /// The stamped date for the current stage, if any (drives badges/detail display).
    var currentDate: Date? {
        switch stage {
        case .saved: nil
        case .applied: appliedDate
        case .interviewing: interviewDate
        case .offer: offerDate
        case .accepted, .declined, .rejected, .withdrawn: closedDate
        }
    }
}
