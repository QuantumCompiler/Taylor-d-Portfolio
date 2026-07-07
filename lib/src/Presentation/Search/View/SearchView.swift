//
//  SearchView.swift
//  Taylor'd Portfolio
//
//  Presentation · Search · View
//

import SwiftUI

/// Search form: role/location/salary in, a ranking run triggered.
struct SearchView: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search").font(.largeTitle.bold())

            Form {
                TextField("Role or keywords", text: $viewModel.keywords)
                TextField("Location (optional)", text: $viewModel.location)
                TextField("Minimum salary (optional)", text: $viewModel.salaryMin)
            }
            .frame(maxHeight: 140)

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

            if !viewModel.results.isEmpty {
                Label("\(viewModel.results.count) ranked results — see the Results tab.",
                      systemImage: "checkmark.circle")
                    .font(.callout).foregroundStyle(.green)
            }

            Spacer()
        }
        .padding(24)
    }
}

#if DEBUG
#Preview {
    let vm = SearchViewModel(searchAndRank: Preview.searchAndRank)
    vm.profile = Preview.sampleProfile
    return SearchView(viewModel: vm)
}
#endif
