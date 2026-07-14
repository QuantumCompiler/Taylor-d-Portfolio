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

    /// Fetches `url` and returns its **readable plain text** (stripped of markup), without
    /// extracting a listing — for callers that want the raw posting text, e.g. enrichment
    /// (v0.6.0 Milestone A-C). Throws ``JobPostingSourceError/unreadable`` on the same
    /// failure modes as ``fetchPosting(from:)``. Has a default that throws `.unreadable`, so
    /// conformers that don't fetch pages need no change.
    func readableText(from url: URL) async throws -> String
}

extension JobPostingSource {
    /// Default: no readable-text capability. Real page-fetching sources override this;
    /// because it's a protocol requirement, calls through `any JobPostingSource` still
    /// dispatch to the override.
    func readableText(from url: URL) async throws -> String {
        throw JobPostingSourceError.unreadable
    }
}

/// Errors raised while reading a single posting.
enum JobPostingSourceError: Error, Equatable {
    /// The page couldn't be read as a job posting (JS-gated, paywalled, empty, blocked,
    /// or not a posting). The caller should ask the user to paste the text instead —
    /// never invent a role from a failed fetch.
    case unreadable
}
