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

    @Test func nextAndPreviousSubViewStepAndClamp() {
        let nav = ShellNavigation(area: .portfolio)   // 3 sub-views
        #expect(nav.selectedSubView == 0)
        nav.nextSubView()
        #expect(nav.selectedSubView == 1)
        nav.nextSubView()
        nav.nextSubView()                              // clamps at the last (index 2)
        #expect(nav.selectedSubView == 2)
        nav.previousSubView()
        #expect(nav.selectedSubView == 1)
        nav.previousSubView()
        nav.previousSubView()                          // clamps at the first (index 0)
        #expect(nav.selectedSubView == 0)
    }

    @Test func nextSubViewIsANoOpForSingleSubViewAreas() {
        let nav = ShellNavigation(area: .results)      // 1 sub-view ("Ranked")
        nav.nextSubView()
        #expect(nav.selectedSubView == 0)
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
