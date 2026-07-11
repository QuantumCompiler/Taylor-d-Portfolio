//
//  ResultsView.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · View
//

import SwiftUI

/// The ranked results list. Tapping a job opens its detail view (from which the user
/// can read the full posting, generate an application, and set its status).
struct ResultsView: View {
    @Bindable var viewModel: ResultsViewModel
    let profile: CandidateProfile?
    let applicationViewModel: ApplicationViewModel
    var markStatus: MarkStatusUseCase? = nil
    var loadStatus: LoadStatusUseCase? = nil
    /// The candidate's real documents for grounded generation (Milestone T).
    var grounding: PortfolioGrounding? = nil

    @State private var showFilters = false

    var body: some View {
        Group {
            if viewModel.isEmpty {
                ContentUnavailableView(
                    "No results yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Run a search to see jobs ranked against your profile.")
                )
            } else {
                VStack(spacing: 0) {
                    filterBar
                    if viewModel.isFilteredEmpty {
                        ContentUnavailableView {
                            Label("No results match your filters", systemImage: "line.3.horizontal.decrease.circle")
                        } description: {
                            Text("Clear or loosen your filters to see the ranked results.")
                        } actions: {
                            Button("Clear filters") { viewModel.clearFilter() }.clickableCursor()
                        }
                    } else {
                        List(viewModel.filteredResults) { ranked in
                            HStack(spacing: 8) {
                                RankedRow(ranked: ranked, status: viewModel.status(for: ranked))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .onTapGesture { viewModel.select(ranked) }
                                    .clickableCursor()
                                if viewModel.supportsRowActions {
                                    rowActions(ranked)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Results")
        .task { await viewModel.loadSavedIfNeeded() }
        .sheet(item: $viewModel.selectedJob) { ranked in
            JobDetailView(
                ranked: ranked, profile: profile, applicationViewModel: applicationViewModel,
                markStatus: markStatus, loadStatus: loadStatus, grounding: grounding,
                canGenerate: false,                              // generation lives in the Tracker (V-D)
                onSaveToTracker: { Task { await viewModel.saveToTracker(ranked) } }
            )
        }
        // Refresh badges after the detail sheet (where status can change) closes.
        .onChange(of: viewModel.selectedJob) { _, newValue in
            if newValue == nil { Task { await viewModel.refreshStatuses() } }
        }
    }

    // MARK: Filter bar (Milestone W)

    private var filterBar: some View {
        DisclosureGroup(isExpanded: $showFilters) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Minimum rank").frame(width: 120, alignment: .leading).foregroundStyle(.secondary)
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.filter.minScore ?? 0) },
                            set: { viewModel.filter.minScore = $0 >= 1 ? Int($0) : nil }
                        ),
                        in: 0...100, step: 5
                    ).frame(maxWidth: 200).clickableCursor()
                    Text(viewModel.filter.minScore.map { "\($0)+" } ?? "Any").monospacedDigit()
                }
                filterField("Keywords") {
                    TextField("Any", text: $viewModel.filter.keywords).textFieldStyle(.roundedBorder).frame(maxWidth: 220)
                }
                filterField("Location") {
                    optionPicker(selection: $viewModel.filter.location, options: viewModel.locationOptions)
                }
                filterField("Company") {
                    optionPicker(selection: $viewModel.filter.company, options: viewModel.companyOptions)
                }
                filterField("Min salary") {
                    TextField("Any", text: Binding(
                        get: { viewModel.filter.salaryMin.map { String(Int($0)) } ?? "" },
                        set: { viewModel.filter.salaryMin = Double($0.filter(\.isNumber)) }
                    )).textFieldStyle(.roundedBorder).frame(maxWidth: 140)
                }
                filterField("Tracked") {
                    Picker("", selection: $viewModel.filter.trackedStatus) {
                        Text("Any").tag(ResultsFilter.TrackedFilter.any)
                        Text("Tracked").tag(ResultsFilter.TrackedFilter.tracked)
                        Text("Not tracked").tag(ResultsFilter.TrackedFilter.untracked)
                    }.pickerStyle(.segmented).labelsHidden().fixedSize().clickableCursor()
                }
            }
            .padding(.top, 6)
        } label: {
            HStack {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                Spacer()
                Text("Showing \(viewModel.visibleCount) of \(viewModel.totalCount)")
                    .font(.caption).foregroundStyle(.secondary)
                if viewModel.filter.isActive {
                    Button("Clear") { viewModel.clearFilter() }.font(.caption).clickableCursor()
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private func filterField<Controls: View>(_ label: String, @ViewBuilder controls: () -> Controls) -> some View {
        HStack(spacing: 8) {
            Text(label).frame(width: 120, alignment: .leading).foregroundStyle(.secondary)
            controls()
            Spacer(minLength: 0)
        }
    }

    /// A picker over `options` (plus "Any") bound to an optional string.
    private func optionPicker(selection: Binding<String?>, options: [String]) -> some View {
        Picker("", selection: Binding(
            get: { selection.wrappedValue ?? "" },
            set: { selection.wrappedValue = $0.isEmpty ? nil : $0 }
        )) {
            Text("Any").tag("")
            ForEach(options, id: \.self) { Text($0).tag($0) }
        }
        .labelsHidden().fixedSize().clickableCursor()
    }

    /// Per-row Save-to-Tracker + Delete icons (Milestone V-A/V-B); each intercepts its own tap.
    private func rowActions(_ ranked: RankedJob) -> some View {
        HStack(spacing: 10) {
            Button { Task { await viewModel.saveToTracker(ranked) } } label: {
                Image(systemName: viewModel.isTracked(ranked) ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.plain).foregroundStyle(.tint)
            .help(viewModel.isTracked(ranked) ? "Saved to Tracker" : "Save to Tracker")
            .clickableCursor()

            Button(role: .destructive) { Task { await viewModel.delete(ranked) } } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain).foregroundStyle(.secondary)
            .help("Delete — removes it and any saved status/materials")
            .clickableCursor()
        }
    }
}

#if DEBUG
#Preview {
    ResultsView(
        viewModel: ResultsViewModel(results: Preview.sampleRankedJobs),
        profile: Preview.sampleProfile,
        applicationViewModel: ApplicationViewModel(generateApplication: Preview.generateApplication)
    )
    .frame(width: 460, height: 400)
}
#endif
