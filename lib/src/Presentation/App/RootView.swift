//
//  RootView.swift
//  Taylor'd Portfolio
//
//  Presentation · App — top-level navigation and shared-state wiring.
//

import SwiftUI

/// Hosts the sidebar-driven shell (v0.4.0 Milestone A), opening straight to the
/// Portfolio area. Owns every screen's ViewModel and connects the cross-screen state
/// (profile → search, results → results area).
///
/// The shell is a `NavigationSplitView`: the **sidebar** is the primary nav (the five
/// top-level areas), and each area's content pane carries a **segmented inner nav** for
/// its sub-views. Milestone A ships one sub-view per area (the existing screen); the
/// per-area split lands in Milestone B. The five screen views are unchanged — only their
/// host moved from the old custom tab bar to this shell.
struct RootView: View {
    @State private var nav = ShellNavigation()

    @State private var portfolio: PortfolioViewModel
    @State private var search: SearchViewModel
    @State private var results: ResultsViewModel
    @State private var tracker: TrackerViewModel
    @State private var settings: SettingsViewModel
    @State private var application: ApplicationViewModel

    private let markStatus: MarkStatusUseCase?
    private let loadStatus: LoadStatusUseCase?

    init(composition: Composition) {
        _portfolio = State(initialValue: composition.makePortfolioViewModel())
        _search = State(initialValue: composition.makeSearchViewModel())
        _results = State(initialValue: composition.makeResultsViewModel())
        _tracker = State(initialValue: composition.makeTrackerViewModel())
        _settings = State(initialValue: composition.makeSettingsViewModel())
        _application = State(initialValue: composition.makeApplicationViewModel())
        markStatus = composition.markStatus
        loadStatus = composition.loadStatus
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            contentPane
        }
        // Profile built or selected on Portfolio flows into Search…
        .onChange(of: portfolio.profile) { _, newProfile in
            search.profile = newProfile
        }
        // …and saving/deleting a profile on Portfolio refreshes Search's picker.
        .onChange(of: portfolio.savedProfiles) { _, _ in
            Task { await search.reloadProfiles() }
        }
        // …and search results flow into the Results area (and jump there).
        .onChange(of: search.results) { _, newResults in
            results.results = newResults
            if !newResults.isEmpty { nav.select(.results) }
        }
    }

    // MARK: Sidebar (primary nav)

    /// The sidebar lists the top-level areas only. Selection uses the standard
    /// accent-fill sidebar style; Results/Tracker carry native count badges. The window
    /// traffic lights sit in the sidebar header (the default `NavigationSplitView` look).
    private var sidebar: some View {
        List(selection: areaSelection) {
            ForEach(MainArea.allCases) { area in
                Label(area.title, systemImage: area.systemImage)
                    .badge(badgeCount(for: area))
                    .tag(area)
                    .clickableCursor()
                    .help(area.title)
            }
        }
        .navigationTitle("Taylor'd Portfolio")
        .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 280)
    }

    /// Binds the `List`'s single selection to the nav holder, routing every change
    /// through `select(_:)` so the inner nav resets to the first sub-view.
    private var areaSelection: Binding<MainArea?> {
        Binding(
            get: { nav.selectedArea },
            set: { if let area = $0 { nav.select(area) } }
        )
    }

    /// Native sidebar badge counts. A zero badge renders as nothing, so unrelated areas
    /// stay clean and Results/Tracker show a count only when they have items.
    private func badgeCount(for area: MainArea) -> Int {
        switch area {
        case .results: results.results.count
        case .tracker: tracker.trackedJobs.count
        default: 0
        }
    }

    // MARK: Content pane (inner nav + sub-view)

    private var contentPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentHeader
            Divider()
            selectedContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(nav.breadcrumbTitle)
    }

    /// The `Area / Sub-view` title above the segmented inner nav.
    private var contentHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(nav.breadcrumbTitle)
                .font(.headline)
            innerNav
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// The inner segmented nav for the selected area's sub-views. Milestone A shows a
    /// single segment per area; Milestone B populates it per the design spec.
    private var innerNav: some View {
        Picker("Sub-view", selection: subViewSelection) {
            ForEach(Array(nav.selectedArea.subViews.enumerated()), id: \.offset) { index, name in
                Text(name).tag(index)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .clickableCursor()
    }

    private var subViewSelection: Binding<Int> {
        Binding(
            get: { nav.selectedSubView },
            set: { nav.selectSubView($0) }
        )
    }

    @ViewBuilder private var selectedContent: some View {
        switch nav.selectedArea {
        case .portfolio:
            PortfolioView(viewModel: portfolio, section: PortfolioSection(index: nav.selectedSubView))
        case .search:
            SearchView(viewModel: search, section: SearchSection(index: nav.selectedSubView))
        case .results:
            ResultsView(
                viewModel: results, profile: portfolio.profile, applicationViewModel: application,
                markStatus: markStatus, loadStatus: loadStatus, grounding: portfolio.grounding
            )
        case .tracker:
            TrackerView(
                viewModel: tracker, section: TrackerSection(index: nav.selectedSubView),
                profile: portfolio.profile, applicationViewModel: application,
                markStatus: markStatus, loadStatus: loadStatus, grounding: portfolio.grounding
            )
        case .settings:
            SettingsView(viewModel: settings, section: SettingsSection(index: nav.selectedSubView))
        }
    }
}

#if DEBUG
#Preview {
    RootView(composition: Composition())
}
#endif
