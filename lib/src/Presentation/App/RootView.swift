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
    /// Shared session (v0.5.0 Milestone B): the detached windows read profile/grounding
    /// from here, and bump its revision when they mutate persistence so the lists reload.
    @Environment(AppSession.self) private var session
    @State private var nav = ShellNavigation()

    @State private var portfolio: PortfolioViewModel
    @State private var search: SearchViewModel
    @State private var results: ResultsViewModel
    @State private var tracker: TrackerViewModel
    @State private var settings: SettingsViewModel

    init(composition: Composition) {
        _portfolio = State(initialValue: composition.makePortfolioViewModel())
        _search = State(initialValue: composition.makeSearchViewModel())
        _results = State(initialValue: composition.makeResultsViewModel())
        _tracker = State(initialValue: composition.makeTrackerViewModel())
        _settings = State(initialValue: composition.makeSettingsViewModel())
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            contentPane
        }
        .background(keyboardShortcuts)
        // Profile built or selected on Portfolio flows into Search…
        .onChange(of: portfolio.profile) { _, newProfile in
            search.profile = newProfile
            session.profile = newProfile
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
        // Keep the shared session's profile/grounding current for the detached windows
        // (v0.5.0 Milestone B).
        .onChange(of: portfolio.grounding) { _, g in session.grounding = g }
        // Entering/clearing Adzuna credentials in Settings re-resolves availability — push it
        // to Search so its banner + Generate gate update without a relaunch (Milestone D-D).
        .onChange(of: settings.adzunaConfigured) { _, configured in
            search.adzunaConfigured = configured
        }
        .onAppear {
            session.profile = portfolio.profile
            session.grounding = portfolio.grounding
        }
        // A detached window mutated persistence (status/generation/save) — reload the lists.
        .onChange(of: session.revision) { _, _ in
            Task {
                await tracker.load()
                await results.refreshHistory()
            }
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
            // No text header — the sidebar names the area and the segmented tabs name the
            // sub-view (v0.4.1 Milestone B). Single-sub-view areas (Results) show neither the
            // tabs nor a header band, so their content fills the pane from the top.
            if nav.selectedArea.subViews.count > 1 {
                contentHeader
                Divider()
            }
            selectedContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Keep the window title the app name — never the area/sub-view.
        .navigationTitle("Taylor'd Portfolio")
    }

    /// The segmented inner nav for the selected area's sub-views (no text title above it —
    /// v0.4.1 Milestone B). Only shown for areas with more than one sub-view. Wrapped in a
    /// horizontal scroll so a many-tab area (the Tracker's All + 8 statuses, v0.4.1 Milestone D)
    /// never overflows the pane; narrow areas (2–3 tabs) fit without scrolling and look the same.
    private var contentHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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

    // MARK: Keyboard navigation (Milestone C)

    /// Invisible controls that give the shell window-wide keyboard navigation:
    /// **⌘1…⌘5** jump to each sidebar area, and **⌘⇧[ / ⌘⇧]** step through the current
    /// area's inner-nav sub-views. Rendered with zero opacity/size so they don't show but
    /// still register their shortcuts. (The sidebar list and segmented control are also
    /// natively keyboard-navigable when focused.)
    private var keyboardShortcuts: some View {
        ZStack {
            ForEach(Array(MainArea.allCases.enumerated()), id: \.element) { index, area in
                Button("Go to \(area.title)") { nav.select(area) }
                    .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: .command)
            }
            Button("Next sub-view") { nav.nextSubView() }
                .keyboardShortcut("]", modifiers: [.command, .shift])
            Button("Previous sub-view") { nav.previousSubView() }
                .keyboardShortcut("[", modifiers: [.command, .shift])
        }
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var selectedContent: some View {
        switch nav.selectedArea {
        case .portfolio:
            PortfolioView(viewModel: portfolio, section: PortfolioSection(index: nav.selectedSubView))
        case .search:
            SearchView(viewModel: search, section: SearchSection(index: nav.selectedSubView))
        case .results:
            ResultsView(viewModel: results)
        case .tracker:
            TrackerView(viewModel: tracker, section: TrackerSection(index: nav.selectedSubView))
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
