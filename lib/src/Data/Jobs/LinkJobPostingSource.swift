//
//  LinkJobPostingSource.swift
//  Taylor'd Portfolio
//
//  Data · Jobs — JobPostingSource that fetches a URL and LLM-extracts the posting.
//

import Foundation

/// A ``JobPostingSource`` that fetches a page over HTTP, strips it to text, and uses
/// the LLM to extract the posting. Fails loudly (``JobPostingSourceError/unreadable``)
/// when a page can't be read — it never guesses a role from a failed fetch.
nonisolated struct LinkJobPostingSource: JobPostingSource {
    let http: any HTTPClient
    let extractor: any LLMProvider
    /// Below this many characters of stripped text, a page is treated as unreadable
    /// (JS-gated shells and error pages carry almost no real text).
    var minReadableCharacters: Int

    init(http: any HTTPClient, extractor: any LLMProvider, minReadableCharacters: Int = 200) {
        self.http = http
        self.extractor = extractor
        self.minReadableCharacters = minReadableCharacters
    }

    func fetchPosting(from url: URL) async throws -> JobListing {
        let data: Data
        do {
            data = try await http.get(url)
        } catch {
            // Any fetch failure (non-2xx, paywall, network, blocked host) is unreadable.
            throw JobPostingSourceError.unreadable
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw JobPostingSourceError.unreadable
        }
        let text = HTMLStripper.plainText(html)
        guard text.count >= minReadableCharacters else {
            throw JobPostingSourceError.unreadable
        }
        return try await extract(text: text, sourceURL: url)
    }

    func extractPosting(fromText text: String, sourceURL: URL?) async throws -> JobListing {
        // Pasted text may still contain markup; strip it the same way.
        let plain = HTMLStripper.plainText(text)
        guard !plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw JobPostingSourceError.unreadable
        }
        return try await extract(text: plain, sourceURL: sourceURL)
    }

    // MARK: Shared extraction

    private func extract(text: String, sourceURL: URL?) async throws -> JobListing {
        let extracted: ExtractedPosting
        do {
            extracted = try await extractor.extractPosting(fromPageText: text)
        } catch {
            throw JobPostingSourceError.unreadable
        }
        // The model reports "no real posting" via empty fields — don't invent one.
        guard extracted.looksReal else { throw JobPostingSourceError.unreadable }
        return extracted.toListing(sourceURL: sourceURL)
    }
}
