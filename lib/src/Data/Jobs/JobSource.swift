//
//  JobSource.swift
//  Taylor'd Portfolio
//
//  Data · Jobs — the swappable job-search seam.
//

import Foundation

/// A source of job listings. Implementations (Adzuna, JSearch, USAJOBS…) translate a
/// `JobQuery` into their own API and return domain `JobListing`s — no API-specific
/// types leak past this protocol.
protocol JobSource: Sendable {
    func search(_ query: JobQuery) async throws -> [JobListing]
}

/// Errors raised while preparing or interpreting a job search.
enum JobSourceError: Error, Equatable {
    /// The request URL couldn't be formed from the query/credentials.
    case invalidURL
}
