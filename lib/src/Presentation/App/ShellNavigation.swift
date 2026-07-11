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

    /// The labels shown in the area's inner segmented nav, in order. Derived from the
    /// per-area section enums below so the nav taxonomy has a single source of truth —
    /// the labels here and the routing in `RootView` can never drift apart. Results is
    /// a single "Ranked" view, so it has one segment.
    var subViews: [String] {
        switch self {
        case .portfolio: PortfolioSection.allCases.map(\.title)
        case .search: SearchSection.allCases.map(\.title)
        case .results: ["Ranked"]
        case .tracker: TrackerSection.allCases.map(\.title)
        case .settings: SettingsSection.allCases.map(\.title)
        }
    }
}

// MARK: - Per-area sub-views (v0.4.0 Milestone B)
//
// Each area's inner segmented nav is a small `Int`-backed enum: `rawValue` is the segment
// index (so `ShellNavigation.selectedSubView` maps straight to a case) and `title` is the
// segment label. `init(index:)` clamps an out-of-range index to the first case, so the shell
// always resolves to a valid sub-view.

/// Portfolio sub-views: build a profile, browse saved profiles, read the tidied source docs.
enum PortfolioSection: Int, CaseIterable {
    case profile, savedProfiles, sourceDocuments

    var title: String {
        switch self {
        case .profile: "Profile"
        case .savedProfiles: "Saved Profiles"
        case .sourceDocuments: "Source Documents"
        }
    }

    init(index: Int) { self = PortfolioSection(rawValue: index) ?? .profile }
}

/// Search sub-views: a new keyword search, the saved-search library, or a single posting URL.
enum SearchSection: Int, CaseIterable {
    case newSearch, savedSearches, fromLink

    var title: String {
        switch self {
        case .newSearch: "New Search"
        case .savedSearches: "Saved Searches"
        case .fromLink: "From a Link"
        }
    }

    init(index: Int) { self = SearchSection(rawValue: index) ?? .newSearch }
}

/// Tracker sub-views: the tracked list, filtered by application stage (`All` shows everything).
enum TrackerSection: Int, CaseIterable {
    case all, applied, interviewing, offers

    var title: String {
        switch self {
        case .all: "All"
        case .applied: "Applied"
        case .interviewing: "Interviewing"
        case .offers: "Offers"
        }
    }

    init(index: Int) { self = TrackerSection(rawValue: index) ?? .all }

    /// Whether a tracked job at `stage` belongs in this section. `All` shows everything;
    /// `Offers` groups a received offer with an accepted one. Other terminal outcomes
    /// (rejected / declined / withdrawn) and not-yet-applied `saved` jobs show only under
    /// `All`. Pure, so it's unit-tested.
    func includes(_ stage: ApplicationStage) -> Bool {
        switch self {
        case .all: true
        case .applied: stage == .applied
        case .interviewing: stage == .interviewing
        case .offers: stage == .offer || stage == .accepted
        }
    }
}

/// Settings sub-views: per-task engines, the Adzuna country/credentials, and About.
enum SettingsSection: Int, CaseIterable {
    case engines, adzuna, about

    var title: String {
        switch self {
        case .engines: "Engines"
        case .adzuna: "Adzuna"
        case .about: "About"
        }
    }

    init(index: Int) { self = SettingsSection(rawValue: index) ?? .engines }
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

    /// Moves to the next sub-view in the current area (clamped at the last), for keyboard
    /// navigation (⌘⇧]). No-op for single-sub-view areas.
    func nextSubView() {
        let count = selectedArea.subViews.count
        guard count > 1 else { return }
        selectedSubView = min(selectedSubView + 1, count - 1)
    }

    /// Moves to the previous sub-view in the current area (clamped at the first), for
    /// keyboard navigation (⌘⇧[).
    func previousSubView() {
        selectedSubView = max(selectedSubView - 1, 0)
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
