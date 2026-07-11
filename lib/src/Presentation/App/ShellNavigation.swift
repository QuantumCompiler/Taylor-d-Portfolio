//
//  ShellNavigation.swift
//  Taylor'd Portfolio
//
//  Presentation · App — navigation state for the sidebar shell (v0.4.0 Milestone A).
//

import SwiftUI

/// The five top-level areas shown in the sidebar (primary navigation).
///
/// Sidebar rows are **top-level areas only** — no nested rows (a deliberate v0.4.0
/// decision: the sidebar stays a clean area switcher, and each area's sub-screens
/// live in the inner segmented nav instead).
enum MainArea: String, CaseIterable, Identifiable, Hashable {
    case portfolio, search, results, tracker, settings

    var id: Self { self }

    var title: String {
        switch self {
        case .portfolio: "Portfolio"
        case .search: "Search"
        case .results: "Results"
        case .tracker: "Tracker"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .portfolio: "person.text.rectangle"
        case .search: "magnifyingglass"
        case .results: "list.number"
        case .tracker: "briefcase"
        case .settings: "gearshape"
        }
    }

    /// The sub-views shown in the area's inner segmented nav.
    ///
    /// **v0.4.0 Milestone A ships one segment per area** — the existing whole screen —
    /// so the segmented control is present (consistent pattern) but a no-op switcher.
    /// **Milestone B** expands these lists (e.g. Portfolio → Profile / Saved Profiles /
    /// Source Documents) and splits the screen content behind them.
    var subViews: [String] {
        switch self {
        case .portfolio: ["Portfolio"]
        case .search: ["Search"]
        case .results: ["Results"]
        case .tracker: ["Tracker"]
        case .settings: ["Settings"]
        }
    }
}

/// Holds the shell's navigation state: which area is selected in the sidebar and which
/// sub-view is selected in that area's inner segmented nav. Kept as a small, testable
/// holder (rather than loose `@State` in `RootView`) so the reset/breadcrumb rules have
/// a home and unit coverage.
@MainActor
@Observable
final class ShellNavigation {
    /// The area currently selected in the sidebar. Change it via ``select(_:)`` so the
    /// sub-view resets — this stays `private(set)` to keep that invariant.
    private(set) var selectedArea: MainArea

    /// The index of the selected sub-view within ``selectedArea``'s inner nav.
    private(set) var selectedSubView: Int

    init(area: MainArea = .portfolio) {
        selectedArea = area
        selectedSubView = 0
    }

    /// Selects a sidebar area. Switching areas **resets the inner nav to the first
    /// sub-view**; re-selecting the current area is a no-op (keeps its sub-view).
    func select(_ area: MainArea) {
        guard area != selectedArea else { return }
        selectedArea = area
        selectedSubView = 0
    }

    /// Selects a sub-view within the current area's inner nav. Negative indices are
    /// ignored; the segmented control only ever offers valid indices.
    func selectSubView(_ index: Int) {
        guard index >= 0 else { return }
        selectedSubView = index
    }

    /// The content-pane title: `Area / Sub-view` when the area has more than one
    /// sub-view, otherwise just the area name (Milestone A, where each area is a
    /// single view, reads as the bare area name).
    var breadcrumbTitle: String {
        let subs = selectedArea.subViews
        guard subs.count > 1, subs.indices.contains(selectedSubView) else {
            return selectedArea.title
        }
        return "\(selectedArea.title) / \(subs[selectedSubView])"
    }
}
