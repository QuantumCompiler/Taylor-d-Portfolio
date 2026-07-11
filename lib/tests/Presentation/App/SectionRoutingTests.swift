//
//  SectionRoutingTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · App — the per-area inner-nav sub-view taxonomy (v0.4.0 Milestone B).
//

import Testing
@testable import Taylor_d_Portfolio

@MainActor
@Suite("Section routing")
struct SectionRoutingTests {

    // MARK: MainArea.subViews reflects each area's sections, in order

    @Test func subViewLabelsMatchTheSectionEnums() {
        #expect(MainArea.portfolio.subViews == ["Profile", "Saved Profiles", "Source Documents"])
        #expect(MainArea.search.subViews == ["New Search", "Saved Searches", "From a Link"])
        #expect(MainArea.results.subViews == ["Ranked"])
        #expect(MainArea.tracker.subViews == ["All", "Applied", "Interviewing", "Offers"])
        #expect(MainArea.settings.subViews == ["Engines", "Adzuna", "About"])
    }

    @Test func sectionLabelsMatchTheSubViewOrder() {
        // The segment index (rawValue) must line up with the label position, or the
        // segmented control would route to the wrong sub-view.
        #expect(PortfolioSection.allCases.map(\.title) == MainArea.portfolio.subViews)
        #expect(SearchSection.allCases.map(\.title) == MainArea.search.subViews)
        #expect(TrackerSection.allCases.map(\.title) == MainArea.tracker.subViews)
        #expect(SettingsSection.allCases.map(\.title) == MainArea.settings.subViews)
    }

    // MARK: init(index:) resolves a segment index, clamping out-of-range to the first case

    @Test func sectionInitResolvesIndexAndClamps() {
        #expect(PortfolioSection(index: 0) == .profile)
        #expect(PortfolioSection(index: 2) == .sourceDocuments)
        #expect(PortfolioSection(index: 99) == .profile)   // out of range → first
        #expect(PortfolioSection(index: -1) == .profile)

        #expect(SearchSection(index: 1) == .savedSearches)
        #expect(SearchSection(index: 5) == .newSearch)

        #expect(TrackerSection(index: 3) == .offers)
        #expect(TrackerSection(index: 4) == .all)

        #expect(SettingsSection(index: 2) == .about)
        #expect(SettingsSection(index: 7) == .engines)
    }

    // MARK: TrackerSection stage-filter policy

    @Test func trackerAllIncludesEveryStage() {
        for stage in ApplicationStage.allCases {
            #expect(TrackerSection.all.includes(stage))
        }
    }

    @Test func trackerAppliedAndInterviewingMatchExactly() {
        #expect(TrackerSection.applied.includes(.applied))
        #expect(!TrackerSection.applied.includes(.interviewing))
        #expect(!TrackerSection.applied.includes(.saved))

        #expect(TrackerSection.interviewing.includes(.interviewing))
        #expect(!TrackerSection.interviewing.includes(.applied))
    }

    @Test func trackerOffersGroupsOfferAndAccepted() {
        #expect(TrackerSection.offers.includes(.offer))
        #expect(TrackerSection.offers.includes(.accepted))
        #expect(!TrackerSection.offers.includes(.applied))
        #expect(!TrackerSection.offers.includes(.rejected))
    }

    @Test func trackerStageFiltersExcludeUnrelatedTerminalAndSavedStages() {
        // saved / rejected / declined / withdrawn appear only under "All".
        for stage in [ApplicationStage.saved, .rejected, .declined, .withdrawn] {
            #expect(!TrackerSection.applied.includes(stage))
            #expect(!TrackerSection.interviewing.includes(stage))
            #expect(!TrackerSection.offers.includes(stage))
            #expect(TrackerSection.all.includes(stage))
        }
    }
}
