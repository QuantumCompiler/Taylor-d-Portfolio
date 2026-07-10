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

            Form {
                locationRow
                Picker("Minimum salary", selection: $viewModel.salaryMin) {
                    Text("Any").tag(Int?.none)
                    ForEach(viewModel.salaryPresets, id: \.self) { amount in
                        Text("$\(amount.formatted())+").tag(Int?.some(amount))
                    }
                }
            }
            .frame(maxHeight: 120)

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

            if viewModel.canUseLink {
                Divider()
                linkSection
            }

            Spacer()
        }
        .padding(24)
        .task { await viewModel.reloadProfiles() }
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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.tint.opacity(0.15), in: Capsule())
        .onLongPressGesture { viewModel.saveAsCommonRoleTitle(title) }
        .help("Long-press to save to your common role titles")
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
            Button {
                viewModel.removeCommonRoleTitle(title)
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(selected ? Color.white.opacity(0.8) : Color.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(selected ? Color.accentColor : Color.accentColor.opacity(0.15), in: Capsule())
    }

    private var locationRow: some View {
        Picker("Location", selection: $viewModel.location) {
            Text("Anywhere").tag("")
            ForEach(viewModel.locationOptions, id: \.self) { place in
                Text(place).tag(place)
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
