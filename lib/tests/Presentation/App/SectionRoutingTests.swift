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
        #expect(MainArea.tracker.subViews == ["All", "Saved", "Applied", "Interviewing", "Offer", "Accepted", "Declined", "Rejected", "Withdrawn"])
        #expect(MainArea.settings.subViews == ["Engines", "Sources", "About"])
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

        #expect(TrackerSection(index: 3) == .interviewing)
        #expect(TrackerSection(index: 8) == .withdrawn)    // last stage tab
        #expect(TrackerSection(index: 9) == .all)          // out of range → first

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

    @Test func everyStageTabMatchesExactlyItsOwnStage() {
        // Each non-All tab maps to exactly one stage and includes only that stage (v0.4.1 D:
        // Offer and Accepted are now separate tabs, no longer bundled).
        for section in TrackerSection.allCases where section != .all {
            guard let stage = section.stage else { Issue.record("non-All section missing a stage"); continue }
            #expect(section.includes(stage))
            for other in ApplicationStage.allCases where other != stage {
                #expect(!section.includes(other))
            }
        }
    }

    @Test func offerAndAcceptedAreDistinctTabs() {
        #expect(TrackerSection.offer.includes(.offer))
        #expect(!TrackerSection.offer.includes(.accepted))
        #expect(TrackerSection.accepted.includes(.accepted))
        #expect(!TrackerSection.accepted.includes(.offer))
    }

    @Test func everyStageHasItsOwnReachableTab() {
        // Milestone D: every ApplicationStage is directly reachable via exactly one tab.
        for stage in ApplicationStage.allCases {
            let matches = TrackerSection.allCases.filter { $0 != .all && $0.includes(stage) }
            #expect(matches.map(\.stage) == [stage])
        }
    }
}
