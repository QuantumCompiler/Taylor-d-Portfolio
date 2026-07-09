//
//  TrackerView.swift
//  Taylor'd Portfolio
//
//  Presentation · Tracker · View
//

import SwiftUI

/// Lists the jobs the user is tracking (has marked with a status). Tapping one opens
/// its detail view, where the status can be advanced.
struct TrackerView: View {
    @Bindable var viewModel: TrackerViewModel
    let profile: CandidateProfile?
    let applicationViewModel: ApplicationViewModel
    var markStatus: MarkStatusUseCase? = nil
    var loadStatus: LoadStatusUseCase? = nil

    var body: some View {
        Group {
            if viewModel.isEmpty {
                ContentUnavailableView(
                    "No tracked applications",
                    systemImage: "briefcase",
                    description: Text("Mark a job as applied from its detail view to track it here.")
                )
            } else {
                List(viewModel.trackedJobs) { tracked in
                    RankedRow(ranked: tracked.job, status: tracked.status)
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.select(tracked.job) }
                }
            }
        }
        .navigationTitle("Tracker")
        .task { await viewModel.load() }
        .sheet(item: $viewModel.selectedJob) { ranked in
            JobDetailView(
                ranked: ranked, profile: profile, applicationViewModel: applicationViewModel,
                markStatus: markStatus, loadStatus: loadStatus
            )
        }
        // Re-load after the detail sheet (where status can change) closes.
        .onChange(of: viewModel.selectedJob) { _, newValue in
            if newValue == nil { Task { await viewModel.load() } }
        }
    }
}

#if DEBUG
#Preview {
    let vm = TrackerViewModel()
    return TrackerView(
        viewModel: vm,
        profile: Preview.sampleProfile,
        applicationViewModel: ApplicationViewModel(generateApplication: Preview.generateApplication)
    )
    .frame(width: 460, height: 400)
}
#endif
