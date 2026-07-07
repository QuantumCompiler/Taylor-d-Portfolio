//
//  JobListing.swift
//  Taylor'd Portfolio
//
//  Data · Models — a single job posting from a JobSource.
//

import Foundation

/// A single job posting as returned by a `JobSource`.
///
/// Plain `Codable` data — deliberately *not* `Generable`, because it comes from a
/// job API, not from the language model.
nonisolated struct JobListing: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var company: String
    var location: String
    var description: String
    var url: URL?
    var salary: SalaryRange?

    init(
        id: String,
        title: String,
        company: String,
        location: String,
        description: String,
        url: URL? = nil,
        salary: SalaryRange? = nil
    ) {
        self.id = id
        self.title = title
        self.company = company
        self.location = location
        self.description = description
        self.url = url
        self.salary = salary
    }
}
