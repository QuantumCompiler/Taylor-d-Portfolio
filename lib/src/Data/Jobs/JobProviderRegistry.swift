//
//  JobProviderRegistry.swift
//  Taylor'd Portfolio
//
//  Data · Jobs — the enumerable source of truth for search providers (v0.6.0 Milestone H-A).
//

import Foundation

/// Everything the app needs to know about one search provider, in one place: its identity,
/// display name, the credential fields the user enters (with UI labels), where to sign up for
/// a key (Milestone G), and a factory that builds its ``JobSource`` from resolved credentials.
///
/// This is the **single source of truth** the credential UI (D), the setup-help links (G), the
/// composite fan-out (F), and the provider selector (H) all read — so a new provider is added
/// by appending **one** descriptor to ``JobProviderRegistry/all``, never by hand-enumerating
/// providers in a view or the composition root.
nonisolated struct JobProviderDescriptor: Sendable, Identifiable {
    /// One credential field + the label its `SecureField` shows.
    struct CredentialField: Sendable {
        let field: JobCredentialField
        let label: String
    }

    let provider: JobProvider
    let displayName: String
    /// The credential fields, in display order.
    let credentialFields: [CredentialField]
    /// The provider's developer sign-up / API-docs page — a static, known URL (never derived
    /// from a job posting), safe to link out to.
    let setupURL: URL
    /// A few terse, offline/rot-proof setup steps (optional; may be empty).
    let setupSteps: [String]
    /// Builds this provider's `JobSource` from resolved credential values (`resolve`), the
    /// shared HTTP client, and the Adzuna country preference. Returns `nil` when a required
    /// credential is missing — the caller then omits the provider (fail-soft).
    let makeSource: @Sendable (
        _ resolve: @Sendable (JobCredentialField) -> String?,
        _ http: any HTTPClient,
        _ country: String
    ) -> (any JobSource)?

    var id: String { provider.rawValue }
}

/// The registered search providers, in display / preference order. Adzuna is the primary
/// (free) source; JSearch is an optional aggregator. Add a provider by appending a descriptor.
nonisolated enum JobProviderRegistry {
    static let all: [JobProviderDescriptor] = [.adzuna, .jsearch]

    /// The descriptor for `provider`, if registered.
    static func descriptor(for provider: JobProvider) -> JobProviderDescriptor? {
        all.first { $0.provider == provider }
    }
}

extension JobProviderDescriptor {
    nonisolated static let adzuna = JobProviderDescriptor(
        provider: .adzuna,
        displayName: "Adzuna",
        credentialFields: [
            .init(field: .adzunaAppID, label: "App ID"),
            .init(field: .adzunaAppKey, label: "App Key"),
        ],
        setupURL: URL(string: "https://developer.adzuna.com/")!,
        setupSteps: [
            "Create a free Adzuna developer account.",
            "Register an app to get your App ID and App Key.",
            "Paste them here.",
        ],
        makeSource: { resolve, http, country in
            guard let appID = resolve(.adzunaAppID), let appKey = resolve(.adzunaAppKey) else { return nil }
            return AdzunaJobSource(
                credentials: .init(appID: appID, appKey: appKey, country: country),
                http: http
            )
        }
    )

    nonisolated static let jsearch = JobProviderDescriptor(
        provider: .jsearch,
        displayName: "JSearch (RapidAPI)",
        credentialFields: [
            .init(field: .jsearchAPIKey, label: "API Key"),
        ],
        setupURL: URL(string: "https://rapidapi.com/letscrape-6bRBa3QguO5/api/jsearch")!,
        setupSteps: [
            "Create a free RapidAPI account and subscribe to the JSearch API.",
            "Copy your RapidAPI application key.",
            "Paste it here. (Mind the free-tier request limit.)",
        ],
        makeSource: { resolve, http, _ in
            guard let apiKey = resolve(.jsearchAPIKey) else { return nil }
            return JSearchJobSource(credentials: .init(apiKey: apiKey), http: http)
        }
    )
}
