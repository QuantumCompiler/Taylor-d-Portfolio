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

    var body: some View {
        Group {
            if viewModel.isEmpty {
                ContentUnavailableView(
                    "No results yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Run a search to see jobs ranked against your profile.")
                )
            } else {
                List(viewModel.results) { ranked in
                    HStack(spacing: 8) {
                        RankedRow(ranked: ranked, status: viewModel.status(for: ranked))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture { viewModel.select(ranked) }
                        if viewModel.supportsRowActions {
                            rowActions(ranked)
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

    /// Per-row Save-to-Tracker + Delete icons (Milestone V-A/V-B); each intercepts its own tap.
    private func rowActions(_ ranked: RankedJob) -> some View {
        HStack(spacing: 10) {
            Button { Task { await viewModel.saveToTracker(ranked) } } label: {
                Image(systemName: viewModel.isTracked(ranked) ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.plain).foregroundStyle(.tint)
            .help(viewModel.isTracked(ranked) ? "Saved to Tracker" : "Save to Tracker")

            Button(role: .destructive) { Task { await viewModel.delete(ranked) } } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain).foregroundStyle(.secondary)
            .help("Delete — removes it and any saved status/materials")
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
