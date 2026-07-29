//
//  PostingMetaBadge.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · View — at-a-glance chips derived from a listing's richer detail.
//

import Foundation

/// A compact metadata chip for a listing's richer posting detail (v0.6.0 Milestone A-F):
/// work type, employment type(s), posted date, and category.
///
/// Pure and SwiftUI-free (it carries a semantic ``Kind`` rather than a `Color`), so the
/// derivation is unit-testable without a view; `JobDetailView` / `RankedRow` map each `kind`
/// to a tint and render it with `FacetBadge`. An un-enriched listing yields **no** chips, so
/// existing rows/detail are visually unchanged.
nonisolated struct PostingMetaBadge: Equatable {
    enum Kind: Equatable { case workType, employment, posted, category }

    let text: String
    let systemImage: String
    let kind: Kind

    /// The chips for `listing`, in display order: work type → employment type(s) → posted date
    /// → category. Empty when the listing carries none of them.
    static func badges(for listing: JobListing, calendar: Calendar = .current, now: Date = Date()) -> [PostingMetaBadge] {
        var badges: [PostingMetaBadge] = []
        if let work = listing.details?.workType {
            badges.append(.init(text: work.label, systemImage: "building.2", kind: .workType))
        }
        for type in listing.positionTypes {
            badges.append(.init(text: type.label, systemImage: "briefcase", kind: .employment))
        }
        if let posted = listing.postedDate {
            badges.append(.init(text: postedText(posted, calendar: calendar, now: now), systemImage: "calendar", kind: .posted))
        }
        if let category = listing.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
            badges.append(.init(text: category, systemImage: "tag", kind: .category))
        }
        return badges
    }

    /// A short relative label for a posted date ("Posted today", "Posted 3 days ago"). A
    /// future date (clock skew) degrades gracefully to "Posted recently".
    static func postedText(_ date: Date, calendar: Calendar = .current, now: Date = Date()) -> String {
        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        switch days {
        case ..<0: return "Posted recently"
        case 0: return "Posted today"
        case 1: return "Posted 1 day ago"
        default: return "Posted \(days) days ago"
        }
    }
}
