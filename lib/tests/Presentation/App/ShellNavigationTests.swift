//
//  ShellNavigationTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · App — the sidebar shell's navigation-state holder.
//

import Testing
@testable import Taylor_d_Portfolio

@MainActor
@Suite("ShellNavigation")
struct ShellNavigationTests {

    @Test func opensOnPortfolioFirstSubView() {
        let nav = ShellNavigation()
        #expect(nav.selectedArea == .portfolio)
        #expect(nav.selectedSubView == 0)
    }

    @Test func selectingAnAreaResetsToTheFirstSubView() {
        let nav = ShellNavigation()
        nav.selectSubView(2)
        #expect(nav.selectedSubView == 2)

        nav.select(.tracker)
        #expect(nav.selectedArea == .tracker)
        #expect(nav.selectedSubView == 0)   // reset on area change
    }

    @Test func reselectingTheCurrentAreaKeepsItsSubView() {
        let nav = ShellNavigation(area: .search)
        nav.selectSubView(1)
        nav.select(.search)                 // no-op — same area
        #expect(nav.selectedSubView == 1)
    }

    @Test func selectSubViewIgnoresNegativeIndices() {
        let nav = ShellNavigation()
        nav.selectSubView(1)
        nav.selectSubView(-3)
        #expect(nav.selectedSubView == 1)   // unchanged
    }

    @Test func breadcrumbIsAreaNameWhenAreaHasOneSubView() {
        // Milestone A: every area has a single sub-view, so the breadcrumb is the bare
        // area name (no `Area / Sub-view` split until Milestone B expands the sub-views).
        for area in MainArea.allCases {
            let nav = ShellNavigation(area: area)
            #expect(nav.breadcrumbTitle == area.title)
        }
    }

    @Test func everyAreaHasIconTitleAndAtLeastOneSubView() {
        for area in MainArea.allCases {
            #expect(!area.title.isEmpty)
            #expect(!area.systemImage.isEmpty)
            #expect(!area.subViews.isEmpty)
        }
    }

    @Test func sidebarListsAllFiveAreasInOrder() {
        #expect(MainArea.allCases == [.portfolio, .search, .results, .tracker, .settings])
    }
}
