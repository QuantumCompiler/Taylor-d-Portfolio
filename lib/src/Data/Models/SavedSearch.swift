//
//  SavedSearch.swift
//  Taylor'd Portfolio
//
//  Data · Models — a named, persisted JobSearchRequest the user can re-run.
//

import Foundation

/// A ``JobSearchRequest`` the user has saved so they can re-run it later against the
/// current profile (ROADMAP Milestone R). `id` is a stable identifier assigned at first
/// save; `createdAt` orders the library (newest first); `name` is a human-readable label
/// derived from the request (or provided by the user).
nonisolated struct SavedSearch: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var request: JobSearchRequest
    var createdAt: Date

    init(id: String, name: String, request: JobSearchRequest, createdAt: Date) {
        self.id = id
        self.name = name
        self.request = request
        self.createdAt = createdAt
    }

    /// A friendly default name derived from a request: its titles, plus the location when set.
    static func defaultName(for request: JobSearchRequest) -> String {
        let titles = request.cleanedTitles
        let base = titles.isEmpty ? "Search" : titles.joined(separator: ", ")
        if let location = request.location, !location.trimmingCharacters(in: .whitespaces).isEmpty {
            return "\(base) · \(location)"
        }
        return base
    }
}
