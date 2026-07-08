//
//  SuggestionProviderTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Search — profile-seeded titles + static location/salary suggestions.
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("SuggestionProvider")
struct SuggestionProviderTests {

    private let provider = SuggestionProvider(
        locations: ["Remote", "New York, NY", "Denver, CO"]
    )

    private func profile(titles: [String]) -> CandidateProfile {
        CandidateProfile(seniority: "S", yearsExperience: 1, coreSkills: [], domains: [],
                         targetTitles: titles, summary: "")
    }

    @Test func seededTitlesComeFromTargetTitlesDeduped() {
        let seeded = provider.seededTitles(for: profile(titles: ["iOS Engineer", "iOS Engineer", "  "]))
        #expect(seeded == ["iOS Engineer"])
        #expect(provider.seededTitles(for: nil).isEmpty)
    }

    @Test func locationSuggestionsFilterAndIncludeRemote() {
        #expect(provider.locationSuggestions().contains("Remote"))
        #expect(provider.locationSuggestions(matching: "new") == ["New York, NY"])
    }

    @Test func salaryPresetsAreAscending() {
        let presets = SuggestionProvider.salaryPresets
        #expect(presets == presets.sorted())
        #expect(!presets.isEmpty)
    }
}
