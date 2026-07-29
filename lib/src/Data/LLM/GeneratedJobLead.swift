//
//  GeneratedJobLead.swift
//  Taylor'd Portfolio
//
//  Data · LLM — the structured wire shape for the LLM job source (v0.6.0 Milestone J).
//

import Foundation
import FoundationModels

/// One AI-suggested job lead the model surfaces from the candidate's profile. Deliberately
/// carries **no URL** — the app never presents a model-produced link as a confirmed live
/// posting; the ``LLMJobSource`` attaches a *search-query* URL instead. Mapped to a
/// ``JobListing`` (tagged as AI-suggested) by the source.
@Generable
nonisolated struct GeneratedJobLead: Codable, Equatable, Sendable {
    @Guide(description: "The job title, e.g. \"Senior iOS Engineer\".")
    var title: String
    @Guide(description: "The hiring company's name.")
    var company: String
    @Guide(description: "Where the role is based, or \"Remote\".")
    var location: String
    @Guide(description: "Two or three sentences: what the role is and why it fits this candidate.")
    var summary: String

    init(title: String, company: String, location: String, summary: String) {
        self.title = title
        self.company = company
        self.location = location
        self.summary = summary
    }
}

/// The structured output of an LLM job-search call: a list of leads. A wrapper because both
/// engines emit a single top-level value — `FoundationModelsProvider` decodes it against this
/// `@Generable` type, `ClaudeCodeProvider` decodes JSON of the same shape (`{ "leads": [ … ] }`).
@Generable
nonisolated struct GeneratedJobLeads: Codable, Equatable, Sendable {
    @Guide(description: "The suggested job leads — real, plausibly-current roles that fit the candidate.")
    var leads: [GeneratedJobLead]

    init(leads: [GeneratedJobLead]) {
        self.leads = leads
    }
}
