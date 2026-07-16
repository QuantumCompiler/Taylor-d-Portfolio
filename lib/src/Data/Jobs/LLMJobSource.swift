//
//  LLMJobSource.swift
//  Taylor'd Portfolio
//
//  Data · Jobs — a JobSource that asks the LLM for leads from the candidate's profile
//  (v0.6.0 Milestone J). No API key required.
//

import Foundation

/// A ``JobSource`` that surfaces job leads straight from the candidate's résumé/profile via the
/// ``LLMProvider`` — the "paste your résumé into a fresh Claude session and it finds jobs" flow,
/// wired in as a first-class source so search works with **no API keys**.
///
/// **Transparency (the one hard rule).** These are **AI-suggested leads**, not verified live
/// postings. Each result is tagged ``JobListing/aiSource`` (so the UI labels it "AI-suggested —
/// verify"), and its `url` is a **search query**, never a model-produced posting link.
///
/// **Grounding lives above the seam.** `JobSource.search` carries no profile, so the candidate's
/// ``PortfolioGrounding`` is lifted in via a closure read at search time (mirroring how
/// `SettingsBackedJobSource` reads the Adzuna country live). The composition root points it at the
/// default/most-recent saved profile.
nonisolated struct LLMJobSource: JobSource {
    let provider: any LLMProvider
    /// Reads the candidate's grounding at search time (the default/selected profile), or `nil`.
    let grounding: @Sendable () async -> PortfolioGrounding?

    init(
        provider: any LLMProvider,
        grounding: @escaping @Sendable () async -> PortfolioGrounding? = { nil }
    ) {
        self.provider = provider
        self.grounding = grounding
    }

    func search(_ query: JobQuery) async throws -> [JobListing] {
        let leads = try await provider.searchJobs(query: query, grounding: await grounding())
        return leads.map(Self.listing(from:))
    }

    /// Maps one lead → a `JobListing` tagged AI-suggested, with a **search-query** URL (never a
    /// model-produced posting link) and a deterministic id — so re-runs dedup against each other
    /// (and against API results, via `JobListing.fingerprint`) and persist stably.
    static func listing(from lead: GeneratedJobLead) -> JobListing {
        JobListing(
            id: identifier(for: lead),
            title: lead.title,
            company: lead.company,
            location: lead.location,
            description: lead.summary,
            url: searchURL(for: lead),
            source: JobListing.aiSource
        )
    }

    /// A stable id derived from the normalized title/company/location (same shape as
    /// `JobListing.fingerprint`, prefixed `ai:`).
    static func identifier(for lead: GeneratedJobLead) -> String {
        let parts = [lead.title, lead.company, lead.location]
            .map { $0.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ") }
            .joined(separator: " | ")
        return "ai:" + parts
    }

    /// A web search for the role so the user can find the real posting themselves — a static host
    /// + query string, never a fabricated live-posting URL.
    static func searchURL(for lead: GeneratedJobLead) -> URL? {
        let terms = [lead.title, lead.company, lead.location]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard !terms.isEmpty else { return nil }
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: terms)]
        return components?.url
    }
}
