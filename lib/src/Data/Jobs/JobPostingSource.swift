//
//  JobPostingSource.swift
//  Taylor'd Portfolio
//
//  Data · Jobs — fetch/extract a SINGLE posting (distinct from JobSource's search).
//

import Foundation

/// Turns a single job posting — identified by a URL, or supplied as pasted text —
/// into a domain ``JobListing``. Distinct from ``JobSource`` (which searches many).
protocol JobPostingSource: Sendable {
    /// Fetches the page at `url` and extracts the posting. Throws
    /// ``JobPostingSourceError/unreadable`` when the page can't be read as a posting.
    func fetchPosting(from url: URL) async throws -> JobListing

    /// Extracts a posting from already-obtained text (the "paste the posting" fallback
    /// for pages that can't be fetched). `sourceURL` keys the listing when known.
    func extractPosting(fromText text: String, sourceURL: URL?) async throws -> JobListing
}

/// Errors raised while reading a single posting.
enum JobPostingSourceError: Error, Equatable {
    /// The page couldn't be read as a job posting (JS-gated, paywalled, empty, blocked,
    /// or not a posting). The caller should ask the user to paste the text instead —
    /// never invent a role from a failed fetch.
    case unreadable
}
