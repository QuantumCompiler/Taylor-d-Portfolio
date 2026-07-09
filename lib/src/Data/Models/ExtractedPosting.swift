//
//  ExtractedPosting.swift
//  Taylor'd Portfolio
//
//  Data · Models — a single job posting extracted from a web page / pasted text.
//

import Foundation
import FoundationModels

/// The fields an LLM extracts from the (messy) text of a single job-posting page.
///
/// `@Generable` + `Codable` like the other structured types, so both engines can
/// produce it (constrained decoding on-device; JSON via Claude). Mapped to the domain
/// ``JobListing`` by ``toListing(sourceURL:)``. Empty `title` **and** `company` signal
/// "no real posting found" — the caller then fails loudly rather than inventing a role.
@Generable
nonisolated struct ExtractedPosting: Codable, Equatable, Sendable {
    @Guide(description: "The exact job title, or empty if the page has no clear job posting.")
    var title: String

    @Guide(description: "The hiring company's name, or empty if not stated.")
    var company: String

    @Guide(description: "The job location, e.g. \"Remote\" or \"New York, NY\"; empty if not stated.")
    var location: String

    @Guide(description: "A clean, readable summary of the role: responsibilities, requirements, and tech stack.")
    var description: String

    init(title: String, company: String, location: String, description: String) {
        self.title = title
        self.company = company
        self.location = location
        self.description = description
    }

    /// Whether the extraction found enough to treat the page as a real posting.
    var looksReal: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Maps to a domain ``JobListing``, keyed by the source URL when there is one.
    func toListing(sourceURL: URL?) -> JobListing {
        JobListing(
            id: sourceURL?.absoluteString ?? "pasted-posting-\(description.hashValue)",
            title: title,
            company: company,
            location: location,
            description: description,
            url: sourceURL,
            salary: nil
        )
    }
}
