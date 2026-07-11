//
//  SearchView.swift
//  Taylor'd Portfolio
//
//  Presentation · Search · View
//

import SwiftUI

/// Search form: one or more role-title chips plus a shared location and salary floor,
/// then a merged multi-title ranking run.
struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    /// Expands the "paste the posting text" fallback — opened automatically when a
    /// link fetch fails so the user is pointed straight at the recovery path.
    @State private var showPasteFallback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search").font(.largeTitle.bold())

            if viewModel.supportsSavedProfiles && !viewModel.savedProfiles.isEmpty {
                profilePicker
            }

            titlesSection

            filtersSection

            if let unavailable = viewModel.unavailableMessage {
                Label(unavailable, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout).foregroundStyle(.orange)
            }

            if !viewModel.hasProfile {
                Label("Build your profile on the Portfolio tab to enable search.", systemImage: "info.circle")
                    .font(.callout).foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button(action: { Task { await viewModel.search() } }) {
                    if viewModel.isSearching {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Search")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSearch)
                .clickableCursor()

                if viewModel.supportsSavedSearches {
                    Button {
                        Task { await viewModel.saveCurrentSearch() }
                    } label: {
                        Label("Save Search", systemImage: "bookmark")
                    }
                    .disabled(!viewModel.canSaveSearch)
                    .clickableCursor()
                }

                if let error = viewModel.errorMessage {
                    Text(error).font(.callout).foregroundStyle(.red)
                }
            }

            if let warning = viewModel.warningMessage {
                Label(warning, systemImage: "exclamationmark.circle")
                    .font(.callout).foregroundStyle(.orange)
            }

            if !viewModel.results.isEmpty {
                Label("\(viewModel.results.count) ranked results — see the Results tab.",
                      systemImage: "checkmark.circle")
                    .font(.callout).foregroundStyle(.green)
            }

            if viewModel.supportsSavedSearches && !viewModel.savedSearches.isEmpty {
                savedSearchesSection
            }

            if viewModel.canUseLink {
                Divider()
                linkSection
            }
        }
        .padding(24)
        .scrollableScreen()
        .task { await viewModel.reloadProfiles() }
        .task { await viewModel.reloadSavedSearches() }
    }

    // MARK: Saved searches (Milestone R)

    private var savedSearchesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Saved searches").font(.headline)
            ForEach(viewModel.savedSearches) { saved in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(saved.name).font(.callout).lineLimit(1)
                        Text(savedSearchSummary(saved)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    Button("Run") { Task { await viewModel.runSavedSearch(saved) } }
                        .disabled(!viewModel.hasProfile || viewModel.isSearching)
                        .clickableCursor()
                    Button(role: .destructive) {
                        Task { await viewModel.deleteSavedSearch(saved) }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                    .clickableCursor()
                }
                .padding(.vertical, 2)
            }
        }
    }

    /// A one-line summary of a saved search's optional parameters.
    private func savedSearchSummary(_ saved: SavedSearch) -> String {
        var parts = [String]()
        if let location = saved.request.location, !location.isEmpty { parts.append(location) }
        if let type = saved.request.positionType { parts.append(type.label) }
        if let salary = saved.request.salaryMin { parts.append("$\(Int(salary).formatted())+") }
        if let score = saved.request.minimumScore { parts.append("rank ≥ \(score)") }
        return parts.isEmpty ? "Any location · any filters" : parts.joined(separator: " · ")
    }

    // MARK: Profile selection

    /// Picks which saved profile the search runs against.
    private var profilePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Profile").font(.headline)
            Picker("Profile", selection: $viewModel.selectedProfileID) {
                if viewModel.selectedProfileID == nil {
                    Text("Current (unsaved)").tag(String?.none)
                }
                ForEach(viewModel.savedProfiles) { saved in
                    Text(saved.name).tag(String?.some(saved.id))
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
            .clickableCursor()
        }
    }

    // MARK: From a link (M-A)

    private var linkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Or generate from a specific posting").font(.headline)
            HStack {
                TextField("Paste a job-posting URL", text: $viewModel.postingURL)
                    .textFieldStyle(.roundedBorder)
                Button(action: { Task { await viewModel.fetchFromLink() } }) {
                    if viewModel.isFetchingLink {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Fetch")
                    }
                }
                .disabled(!viewModel.canFetchLink)
                .clickableCursor()
            }

            // Surface a fetch/paste failure prominently, right at the action.
            if let linkError = viewModel.linkErrorMessage {
                Label(linkError, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DisclosureGroup("Page won’t load? Paste the posting text", isExpanded: $showPasteFallback) {
                VStack(alignment: .leading, spacing: 6) {
                    TextEditor(text: $viewModel.pastedPosting)
                        .frame(minHeight: 100)
                        .border(.quaternary)
                    Button("Generate from pasted text") {
                        Task { await viewModel.generateFromPastedText() }
                    }
                    .disabled(!viewModel.hasProfile || viewModel.isFetchingLink)
                    .clickableCursor()
                }
            }
        }
        // A failed fetch opens the paste fallback so the recovery path is visible.
        .onChange(of: viewModel.linkErrorMessage) { _, newValue in
            if newValue != nil { showPasteFallback = true }
        }
    }

    // MARK: Titles (chips + input + suggestions)

    private var titlesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Role titles").font(.headline)

            if !viewModel.titles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.titles, id: \.self) { title in
                            chip(title)
                        }
                    }
                }
                Text("Long-press a title to save it to your common role titles.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                TextField("Add a role title (e.g. iOS Engineer)", text: $viewModel.titleInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { viewModel.addTitle() }
                Button("Add") { viewModel.addTitle() }
                    .disabled(viewModel.titleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    .clickableCursor()
            }

            if !viewModel.commonRoleTitles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Common role titles — tap to include in the search")
                        .font(.caption).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.commonRoleTitles, id: \.self) { title in
                                commonTitleTile(title)
                            }
                        }
                    }
                }
            }
        }
    }

    /// An added-title chip: always searched, removable with its "x". Long-press saves
    /// it to the persisted common-role-titles library.
    private func chip(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title).font(.callout)
            if viewModel.isCommonRoleTitle(title) {
                Image(systemName: "star.fill")
                    .font(.caption2).foregroundStyle(.yellow)
            }
            Button {
                viewModel.removeTitle(title)
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .clickableCursor()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.tint.opacity(0.15), in: Capsule())
        .onLongPressGesture { viewModel.saveAsCommonRoleTitle(title) }
        .help("Long-press to save to your common role titles")
        .clickableCursor()
    }

    /// A common-role-title tile: tap the label to toggle whether it's included in the
    /// search (selected tiles are tinted), and tap the "x" to remove it from the
    /// persisted library.
    private func commonTitleTile(_ title: String) -> some View {
        let selected = viewModel.isCommonTitleSelected(title)
        return HStack(spacing: 4) {
            Text(title)
                .font(.callout)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .contentShape(Rectangle())
                .onTapGesture { viewModel.toggleCommonTitle(title) }
                .clickableCursor()
            Button {
                viewModel.removeCommonRoleTitle(title)
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(selected ? Color.white.opacity(0.8) : Color.secondary)
            .clickableCursor()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(selected ? Color.accentColor : Color.accentColor.opacity(0.15), in: Capsule())
    }

    // MARK: Filters (Milestone U — every field optional)

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Position type (U-A)
            Picker("Position type", selection: $viewModel.positionType) {
                Text("Any").tag(PositionType?.none)
                ForEach(viewModel.positionTypes) { type in
                    Text(type.label).tag(PositionType?.some(type))
                }
            }
            .pickerStyle(.menu).fixedSize()
            .clickableCursor()

            // Location — typeable + saveable (U-B)
            filterRow(label: "Location") {
                TextField("Anywhere", text: $viewModel.location)
                    .textFieldStyle(.roundedBorder).frame(maxWidth: 220)
                presetMenu(viewModel.locationOptions.map { ($0, $0) }) { viewModel.location = $0 }
                Button("Save") { viewModel.saveCurrentLocation() }
                    .disabled(viewModel.location.trimmingCharacters(in: .whitespaces).isEmpty)
                    .clickableCursor()
            }
            savedChips(viewModel.savedLocations, label: { $0 },
                       onTap: { viewModel.location = $0 }, onRemove: viewModel.removeSavedLocation)

            // Minimum salary — typeable + saveable (U-C)
            filterRow(label: "Min salary") {
                TextField("Any", text: $viewModel.salaryText)
                    .textFieldStyle(.roundedBorder).frame(maxWidth: 140)
                presetMenu(viewModel.salaryPresetOptions.map { (String($0), "$\($0.formatted())+") }) {
                    viewModel.salaryText = $0
                }
                Button("Save") { viewModel.saveCurrentSalary() }
                    .disabled(viewModel.effectiveSalaryMin == nil)
                    .clickableCursor()
            }
            savedChips(viewModel.savedSalaries, label: { "$\($0.formatted())+" },
                       onTap: { viewModel.salaryText = String($0) }, onRemove: viewModel.removeSavedSalary)

            // Desired result count (U-D)
            filterRow(label: "Desired results") {
                TextField("Any", text: $viewModel.desiredResultText)
                    .textFieldStyle(.roundedBorder).frame(maxWidth: 100)
                Text("best-effort goal").font(.caption).foregroundStyle(.secondary)
            }

            // Minimum rank filter (U-E)
            filterRow(label: "Minimum rank") {
                Slider(value: $viewModel.minimumScore, in: 0...100, step: 5).frame(maxWidth: 220)
                    .clickableCursor()
                Text(viewModel.minimumScore >= 1 ? "\(Int(viewModel.minimumScore))+" : "Any")
                    .font(.callout).monospacedDigit().frame(width: 44, alignment: .leading)
            }
        }
    }

    /// A labelled filter row: a fixed-width label + trailing controls.
    private func filterRow<Controls: View>(label: String, @ViewBuilder controls: () -> Controls) -> some View {
        HStack(spacing: 8) {
            Text(label).frame(width: 120, alignment: .leading).foregroundStyle(.secondary)
            controls()
            Spacer(minLength: 0)
        }
    }

    /// A "Presets" menu that sets a value from `(value, label)` options.
    private func presetMenu(_ options: [(value: String, label: String)], onPick: @escaping (String) -> Void) -> some View {
        Menu("Presets") {
            ForEach(options, id: \.value) { option in
                Button(option.label) { onPick(option.value) }
            }
        }
        .fixedSize()
        .clickableCursor()
    }

    /// A horizontal row of saved-value chips: tap fills the field, the "x" removes it.
    private func savedChips<Value: Hashable>(
        _ values: [Value],
        label: @escaping (Value) -> String,
        onTap: @escaping (Value) -> Void,
        onRemove: @escaping (Value) -> Void
    ) -> some View {
        Group {
            if !values.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(values, id: \.self) { value in
                            HStack(spacing: 4) {
                                Text(label(value)).font(.caption)
                                    .contentShape(Rectangle())
                                    .onTapGesture { onTap(value) }
                                    .clickableCursor()
                                Button { onRemove(value) } label: { Image(systemName: "xmark.circle.fill") }
                                    .buttonStyle(.plain).foregroundStyle(.secondary)
                                    .clickableCursor()
                            }
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(.tint.opacity(0.15), in: Capsule())
                        }
                    }
                }
                .padding(.leading, 128)
            }
        }
    }
}

#if DEBUG
#Preview {
    let vm = SearchViewModel(
        searchAndRank: Preview.searchAndRank,
        roleTitleStore: RoleTitleStore(store: Preview.MemoryStore())
    )
    vm.profile = Preview.sampleProfile
    return SearchView(viewModel: vm)
}
#endif
