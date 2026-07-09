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
                    RankedRow(ranked: ranked, status: viewModel.status(for: ranked))
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.select(ranked) }
                }
            }
        }
        .navigationTitle("Results")
        .task { await viewModel.loadSavedIfNeeded() }
        .sheet(item: $viewModel.selectedJob) { ranked in
            JobDetailView(
                ranked: ranked, profile: profile, applicationViewModel: applicationViewModel,
                markStatus: markStatus, loadStatus: loadStatus
            )
        }
        // Refresh badges after the detail sheet (where status can change) closes.
        .onChange(of: viewModel.selectedJob) { _, newValue in
            if newValue == nil { Task { await viewModel.refreshStatuses() } }
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
