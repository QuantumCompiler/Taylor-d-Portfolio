//
//  RootView.swift
//  Taylor'd Portfolio
//
//  Presentation · App — top-level navigation and shared-state wiring.
//

import SwiftUI

/// The main tabs, once the user has entered the app.
private enum MainTab: Hashable {
    case portfolio, search, results, tracker, settings
}

/// Hosts the main `TabView`, opening straight to the Portfolio tab. Owns every screen's
/// ViewModel and connects the cross-screen state (profile → search, results → results tab).
struct RootView: View {
    @State private var portfolio: PortfolioViewModel
    @State private var search: SearchViewModel
    @State private var results: ResultsViewModel
    @State private var tracker: TrackerViewModel
    @State private var settings: SettingsViewModel
    @State private var application: ApplicationViewModel

    private let markStatus: MarkStatusUseCase?
    private let loadStatus: LoadStatusUseCase?

    @State private var tab: MainTab = .portfolio

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
        mainTabs
    }

    private var mainTabs: some View {
        TabView(selection: $tab) {
            PortfolioView(viewModel: portfolio)
                .tabItem { Label("Portfolio", systemImage: "person.text.rectangle") }
                .tag(MainTab.portfolio)

            SearchView(viewModel: search)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(MainTab.search)

            ResultsView(
                viewModel: results, profile: portfolio.profile, applicationViewModel: application,
                markStatus: markStatus, loadStatus: loadStatus
            )
                .tabItem { Label("Results", systemImage: "list.number") }
                .tag(MainTab.results)

            TrackerView(
                viewModel: tracker, profile: portfolio.profile, applicationViewModel: application,
                markStatus: markStatus, loadStatus: loadStatus
            )
                .tabItem { Label("Tracker", systemImage: "briefcase") }
                .tag(MainTab.tracker)

            SettingsView(viewModel: settings)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(MainTab.settings)
        }
        // Profile built or selected on Portfolio flows into Search…
        .onChange(of: portfolio.profile) { _, newProfile in
            search.profile = newProfile
        }
        // …and saving/deleting a profile on Portfolio refreshes Search's picker.
        .onChange(of: portfolio.savedProfiles) { _, _ in
            Task { await search.reloadProfiles() }
        }
        // …and search results flow into the Results tab (and jump there).
        .onChange(of: search.results) { _, newResults in
            results.results = newResults
            if !newResults.isEmpty { tab = .results }
        }
    }
}

#if DEBUG
#Preview {
    RootView(composition: Composition())
}
#endif
