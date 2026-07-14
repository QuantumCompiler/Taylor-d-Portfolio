//
//  EnrichPostingUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — enrich a listing with richer posting detail (v0.6.0 Milestone A-C).
//

import Foundation

/// Enriches a ``JobListing`` from its posting page: captures the **full posting text**
/// (v0.6.0 Milestone E) and structures it into ``PostingDetails`` (work type, qualifications,
/// responsibilities, about-role / about-company, benefits — Milestone A) — both from **one**
/// fetch.
///
/// Prefers the **full posting page** — fetched and stripped through the ``JobPostingSource``
/// against the listing's `url` — over Adzuna's often-truncated `description` snippet. When the
/// page fetches richer than the snippet, an LLM pass **cleans it into just the posting**
/// (dropping site navigation, "similar jobs", footer, country lists, etc.) and stores that on
/// `fullDescription` (for grounding + display); the structuring pass then runs on that clean
/// text. Every step is best-effort: a page that can't be fetched (JS-gated / paywalled / no url
/// / no source) falls back to the snippet with no `fullDescription`; if cleaning is
/// unavailable / fails / finds no posting, the noisy raw page is **not** stored (the snippet
/// stands) though structuring still runs on it; and a structuring failure keeps the cleaned
/// full text. Cleaning and structuring only ORGANIZE what the posting says — never invent; when
/// structuring finds nothing (`details.hasContent` is false) `details` is left nil. A listing
/// with no usable text at all is returned unchanged.
nonisolated struct EnrichPostingUseCase: Sendable {
    let provider: any LLMProvider
    /// The full-page fetcher. Optional — `nil` means "snippet only" (no network fetch).
    let postingSource: (any JobPostingSource)?

    init(provider: any LLMProvider, postingSource: (any JobPostingSource)? = nil) {
        self.provider = provider
        self.postingSource = postingSource
    }

    /// Returns `listing` with `.fullDescription` and/or `.details` populated from its posting
    /// page, or unchanged when there's no fuller page and no structure to add.
    func callAsFunction(_ listing: JobListing) async throws -> JobListing {
        let rawPage = await fullPageText(for: listing)

        var result = listing
        // De-chrome the fetched page into just the posting (E). If cleaning is unavailable /
        // fails / finds no posting, keep the snippet rather than store the noisy raw page.
        var structuringText = listing.description
        if let rawPage {
            let cleaned = (try? await provider.cleanPostingText(fromPageText: rawPage)) ?? ""
            if !cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.fullDescription = cleaned
                structuringText = cleaned
            } else {
                structuringText = rawPage   // structure from the raw page (its prompt ignores chrome)
            }
        }

        guard !structuringText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return result }

        // Structuring is best-effort on top of the captured text: a failure (or an empty
        // result) must not discard the full text we just recovered.
        if let details = try? await provider.enrichPosting(fromPostingText: structuringText), details.hasContent {
            result.details = details
        }
        return result
    }

    /// The full posting page text when it fetches and is richer than the snippet, else `nil`
    /// (fall back to the snippet). A fetch failure is swallowed — falling back is the point.
    private func fullPageText(for listing: JobListing) async -> String? {
        guard let postingSource, let url = listing.url,
              let page = try? await postingSource.readableText(from: url),
              page.count > listing.description.count else { return nil }
        return page
    }
}
