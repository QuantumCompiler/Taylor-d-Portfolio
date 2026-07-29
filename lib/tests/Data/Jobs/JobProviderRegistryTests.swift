//
//  JobProviderRegistryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Jobs — the enumerable provider registry (v0.6.0 Milestone H-A / G).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

private struct StubHTTP: HTTPClient {
    func get(_ url: URL) async throws -> Data { Data() }
}

@Suite("JobProviderRegistry")
struct JobProviderRegistryTests {

    @Test func credentialedProvidersHaveHelpAndCredentialFields() {
        for descriptor in JobProviderRegistry.all where descriptor.kind == .credentialed {
            #expect(!descriptor.displayName.isEmpty)
            #expect(!descriptor.credentialFields.isEmpty)
            #expect(descriptor.setupURL?.scheme == "https")   // a real, linkable help page (G)
            // Each listed credential field belongs to this provider.
            #expect(descriptor.credentialFields.allSatisfy { $0.field.provider == descriptor.provider })
        }
    }

    /// The LLM source (Milestone J) is keyless: no credential fields, no sign-up URL.
    @Test func llmProviderIsKeyless() {
        let llm = try! #require(JobProviderRegistry.descriptor(for: .llm))
        #expect(llm.kind == .llm)
        #expect(llm.credentialFields.isEmpty)
        #expect(llm.setupURL == nil)
        #expect(JobProvider.llm.requiredCredentials.isEmpty)
    }

    @Test func registryCoversEveryJobProvider() {
        #expect(Set(JobProviderRegistry.all.map(\.provider)) == Set(JobProvider.allCases))
    }

    @Test func makeSourceBuildsOnlyWhenCredentialsResolve() {
        let adzuna = try! #require(JobProviderRegistry.descriptor(for: .adzuna))
        #expect(adzuna.makeSource({ _ in nil }, StubHTTP(), "us") == nil)                 // no key → omitted
        #expect(adzuna.makeSource({ $0 == .adzunaAppID ? "id" : "key" }, StubHTTP(), "us") != nil)

        let jsearch = try! #require(JobProviderRegistry.descriptor(for: .jsearch))
        #expect(jsearch.makeSource({ _ in nil }, StubHTTP(), "us") == nil)
        #expect(jsearch.makeSource({ _ in "rapid-key" }, StubHTTP(), "us") != nil)
    }
}
