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

    /// Browser-like request headers. Many job boards reject or serve a stripped shell to
    /// non-browser clients (the default URLSession `User-Agent`), so present as a browser
    /// to raise the odds of getting the real posting HTML rather than a 403 / consent page.
    static let browserHeaders: [String: String] = [
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
            + "(KHTML, like Gecko) Version/17.0 Safari/605.1.15",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
    ]

    func fetchPosting(from url: URL) async throws -> JobListing {
        let text = try await readableText(from: url)
        return try await extract(text: text, sourceURL: url)
    }

    /// Fetches the page, decodes it (tolerating non-UTF-8), strips it to plain text, and
    /// guards the min-readable-length threshold — the shared first half of `fetchPosting`,
    /// exposed on its own so enrichment can feed on the full posting text (A-C).
    func readableText(from url: URL) async throws -> String {
        let data: Data
        do {
            data = try await http.get(url, headers: Self.browserHeaders)
        } catch {
            // Any fetch failure (non-2xx, paywall, network, blocked host) is unreadable.
            throw JobPostingSourceError.unreadable
        }
        guard let html = Self.decode(data) else {
            throw JobPostingSourceError.unreadable
        }
        let text = HTMLStripper.plainText(html)
        guard text.count >= minReadableCharacters else {
            throw JobPostingSourceError.unreadable
        }
        return text
    }

    func extractPosting(fromText text: String, sourceURL: URL?) async throws -> JobListing {
        // Pasted text may still contain markup; strip it the same way.
        let plain = HTMLStripper.plainText(text)
        guard !plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw JobPostingSourceError.unreadable
        }
        return try await extract(text: plain, sourceURL: sourceURL)
    }

    // MARK: Decoding

    /// Decodes fetched page bytes to a string, tolerating non-UTF-8 pages. Tries UTF-8
    /// first, then falls back to ISO Latin-1 (which maps every byte, so it never fails) —
    /// so a mis-declared or latin-encoded board isn't wrongly treated as unreadable.
    static func decode(_ data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        return String(data: data, encoding: .isoLatin1)
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
