//
//  EnrichPostingUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — enrich a listing with richer posting detail (v0.6.0 Milestone A-C).
//

import Foundation

/// Enriches a ``JobListing`` with structured ``PostingDetails`` (work type, qualifications,
/// responsibilities, about-role / about-company, benefits) via the LLM enrichment step.
///
/// Prefers the **full posting page** — fetched and stripped through the ``JobPostingSource``
/// against the listing's `url` — over Adzuna's often-truncated `description` snippet, and
/// falls back to the snippet when the page can't be fetched (JS-gated / paywalled / no url /
/// no source wired). Enrichment only ORGANIZES what the posting says; when it finds nothing
/// (`details.hasContent` is false) the listing is returned **unchanged** rather than
/// overwritten with an empty structure.
nonisolated struct EnrichPostingUseCase: Sendable {
    let provider: any LLMProvider
    /// The full-page fetcher. Optional — `nil` means "snippet only" (no network fetch).
    let postingSource: (any JobPostingSource)?

    init(provider: any LLMProvider, postingSource: (any JobPostingSource)? = nil) {
        self.provider = provider
        self.postingSource = postingSource
    }

    /// Returns `listing` with `.details` populated by enrichment, or unchanged when there's
    /// no usable text or enrichment finds nothing.
    func callAsFunction(_ listing: JobListing) async throws -> JobListing {
        let text = await postingText(for: listing)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return listing }

        let details = try await provider.enrichPosting(fromPostingText: text)
        guard details.hasContent else { return listing }

        var enriched = listing
        enriched.details = details
        return enriched
    }

    /// The best text to enrich from: the full posting page when it fetches and is richer than
    /// the snippet, otherwise the listing's own description. A fetch failure is swallowed —
    /// falling back to the snippet is the point, not an error.
    private func postingText(for listing: JobListing) async -> String {
        if let postingSource, let url = listing.url,
           let page = try? await postingSource.readableText(from: url),
           page.count > listing.description.count {
            return page
        }
        return listing.description
    }
}
