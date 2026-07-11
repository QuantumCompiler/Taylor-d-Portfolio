//
//  RootView.swift
//  Taylor'd Portfolio
//
//  Presentation · App — top-level navigation and shared-state wiring.
//

import SwiftUI

/// The main tabs, once the user has entered the app.
private enum MainTab: Hashable, CaseIterable {
    case portfolio, search, results, tracker, settings

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
        VStack(spacing: 0) {
            tabBar
            Divider()
            selectedTab
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

    /// A custom top tab bar (replaces the native `TabView` strip) so clickable tabs can
    /// show the pointing-hand cursor — the native strip is system-drawn and ignores it.
    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases, id: \.self) { item in
                let selected = tab == item
                Button {
                    withAnimation(.easeInOut(duration: 0.12)) { tab = item }
                } label: {
                    Label(item.title, systemImage: item.systemImage)
                        .font(.callout.weight(selected ? .semibold : .regular))
                        .padding(.vertical, 6).padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(selected ? Color.accentColor.opacity(0.15) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .clickableCursor()
                .help(item.title)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    @ViewBuilder private var selectedTab: some View {
        switch tab {
        case .portfolio:
            PortfolioView(viewModel: portfolio)
        case .search:
            SearchView(viewModel: search)
        case .results:
            ResultsView(
                viewModel: results, profile: portfolio.profile, applicationViewModel: application,
                markStatus: markStatus, loadStatus: loadStatus, grounding: portfolio.grounding
            )
        case .tracker:
            TrackerView(
                viewModel: tracker, profile: portfolio.profile, applicationViewModel: application,
                markStatus: markStatus, loadStatus: loadStatus, grounding: portfolio.grounding
            )
        case .settings:
            SettingsView(viewModel: settings)
        }
    }
}

#if DEBUG
#Preview {
    RootView(composition: Composition())
}
#endif
