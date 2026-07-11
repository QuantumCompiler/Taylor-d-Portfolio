//
//  LinkJobPostingSourceTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Jobs — fetch + LLM-extract a single posting, fail loudly.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// A stub `HTTPClient` that returns canned bytes or throws.
private struct StubHTTP: HTTPClient {
    var body: Data = Data()
    var error: Error?
    func get(_ url: URL) async throws -> Data {
        if let error { throw error }
        return body
    }
}

/// An `HTTPClient` that records the headers of the last GET (to prove the fetch presents
/// as a browser). Reference type so the recorded value survives the `nonisolated` call.
private final class RecordingHTTP: HTTPClient, @unchecked Sendable {
    var body: Data
    private(set) var lastHeaders: [String: String] = [:]
    init(body: Data) { self.body = body }
    func get(_ url: URL) async throws -> Data { body }
    func get(_ url: URL, headers: [String: String]) async throws -> Data {
        lastHeaders = headers
        return body
    }
}

/// A stub `LLMProvider` that returns a canned extraction (only `extractPosting` matters).
private struct StubExtractor: LLMProvider {
    var extracted: ExtractedPosting = ExtractedPosting(title: "iOS Engineer", company: "Acme", location: "Remote", description: "Swift.")
    var shouldThrow = false
    struct Boom: Error {}
    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile { .init(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "") }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { [] }
    func extractPosting(fromPageText pageText: String) async throws -> ExtractedPosting {
        if shouldThrow { throw Boom() }
        return extracted
    }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief { .init(company: "", roleTitle: "", mustHaveKeywords: [], niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "") }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit { .init(resumeMarkdown: "", coverLetter: "", gapNote: "") }
}

private let url = URL(string: "https://example.com/jobs/1")!

@Suite("LinkJobPostingSource")
struct LinkJobPostingSourceTests {

    @Test func goodPageExtractsFieldsAndKeepsSourceURL() async throws {
        let html = Data("<html><body><h1>iOS Engineer</h1><p>\(String(repeating: "Swift and SwiftUI. ", count: 30))</p></body></html>".utf8)
        let source = LinkJobPostingSource(http: StubHTTP(body: html), extractor: StubExtractor())

        let listing = try await source.fetchPosting(from: url)
        #expect(listing.title == "iOS Engineer")
        #expect(listing.company == "Acme")
        #expect(listing.url == url)
        #expect(listing.id == url.absoluteString)
    }

    @Test func fetchFailureIsUnreadable() async {
        let source = LinkJobPostingSource(http: StubHTTP(error: HTTPError.status(code: 403, body: Data())), extractor: StubExtractor())
        await #expect(throws: JobPostingSourceError.unreadable) {
            _ = try await source.fetchPosting(from: url)
        }
    }

    @Test func tooLittleTextIsUnreadable() async {
        // A JS-gated shell: almost no real text after stripping.
        let source = LinkJobPostingSource(http: StubHTTP(body: Data("<html><body>Loading…</body></html>".utf8)), extractor: StubExtractor())
        await #expect(throws: JobPostingSourceError.unreadable) {
            _ = try await source.fetchPosting(from: url)
        }
    }

    @Test func emptyExtractionIsUnreadableNotInvented() async {
        // Enough text to pass the length gate, but the model finds no real posting.
        let html = Data(String(repeating: "cookie policy nav footer ", count: 40).utf8)
        let extractor = StubExtractor(extracted: ExtractedPosting(title: "", company: "", location: "", description: ""))
        let source = LinkJobPostingSource(http: StubHTTP(body: html), extractor: extractor)
        await #expect(throws: JobPostingSourceError.unreadable) {
            _ = try await source.fetchPosting(from: url)
        }
    }

    @Test func extractorFailureIsUnreadable() async {
        let html = Data(String(repeating: "Swift and SwiftUI. ", count: 30).utf8)
        let source = LinkJobPostingSource(http: StubHTTP(body: html), extractor: StubExtractor(shouldThrow: true))
        await #expect(throws: JobPostingSourceError.unreadable) {
            _ = try await source.fetchPosting(from: url)
        }
    }

    @Test func pastedTextExtractsWithoutFetching() async throws {
        // No HTTP call — extraction runs on the pasted text directly.
        let source = LinkJobPostingSource(http: StubHTTP(error: HTTPError.nonHTTPResponse), extractor: StubExtractor())
        let listing = try await source.extractPosting(fromText: "iOS Engineer at Acme. Swift.", sourceURL: nil)
        #expect(listing.title == "iOS Engineer")
        #expect(listing.url == nil)
    }

    @Test func emptyPastedTextIsUnreadable() async {
        let source = LinkJobPostingSource(http: StubHTTP(), extractor: StubExtractor())
        await #expect(throws: JobPostingSourceError.unreadable) {
            _ = try await source.extractPosting(fromText: "   ", sourceURL: nil)
        }
    }

    // MARK: Fetch hardening (Hotfix)

    @Test func fetchPresentsAsABrowser() async throws {
        let html = Data("<html><body><h1>iOS Engineer</h1><p>\(String(repeating: "Swift and SwiftUI. ", count: 30))</p></body></html>".utf8)
        let http = RecordingHTTP(body: html)
        let source = LinkJobPostingSource(http: http, extractor: StubExtractor())

        _ = try await source.fetchPosting(from: url)
        // A browser-like User-Agent is sent so boards that block non-browser clients answer.
        #expect(http.lastHeaders["User-Agent"]?.contains("Mozilla/5.0") == true)
        #expect(http.lastHeaders["Accept"] != nil)
    }

    @Test func nonUTF8PageStillDecodesAndExtracts() async throws {
        // A page with a byte that isn't valid UTF-8 (0xE9 = 'é' in ISO Latin-1).
        let latin1 = "<html><body><h1>iOS Engineer</h1><p>\(String(repeating: "Swift café SwiftUI. ", count: 30))</p></body></html>"
        let data = latin1.data(using: .isoLatin1)!
        #expect(String(data: data, encoding: .utf8) == nil)   // genuinely not UTF-8

        let source = LinkJobPostingSource(http: StubHTTP(body: data), extractor: StubExtractor())
        let listing = try await source.fetchPosting(from: url)
        #expect(listing.title == "iOS Engineer")              // decoded via the Latin-1 fallback
    }
}
