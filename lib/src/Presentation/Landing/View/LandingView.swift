//
//  LandingView.swift
//  Taylor'd Portfolio
//
//  Presentation · Landing · View — the first screen the user sees.
//

import SwiftUI

/// Landing screen: what Taylor'd Portfolio does, and a way in.
///
/// A dumb, declarative view (per the architecture) — no business logic, no data
/// access. The "Get Started" button will route into the Search flow once it exists.
struct LandingView: View {
    let viewModel: LandingViewModel

    var body: some View {
        VStack(spacing: 32) {
            header
            features
            callToAction
        }
        .padding(48)
        .frame(minWidth: 520, minHeight: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text("Taylor'd Portfolio")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            Text("Find jobs that fit your portfolio — then generate a tailored resume and cover letter for the ones you choose.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 20) {
            FeatureRow(
                icon: "magnifyingglass",
                title: "Search",
                detail: "Pull real listings from job sources like Adzuna."
            )
            FeatureRow(
                icon: "chart.bar.fill",
                title: "Rank",
                detail: "Score every job against your portfolio with on-device AI."
            )
            FeatureRow(
                icon: "doc.text.fill",
                title: "Generate",
                detail: "Draft a grounded resume and cover letter — you stay in control."
            )
        }
        .frame(maxWidth: 460, alignment: .leading)
    }

    private var callToAction: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.getStarted()
            } label: {
                Text("Get Started")
                    .frame(maxWidth: 220)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Runs on-device with Apple Foundation Models. Never auto-submits an application.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
    }
}

/// A single icon + title + detail row in the feature list.
private struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    LandingView(viewModel: LandingViewModel())
}
