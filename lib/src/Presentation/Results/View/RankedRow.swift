//
//  RankedRow.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · View — one row in the ranked results list.
//

import SwiftUI

/// A single ranked job: score badge + title/company + the model's reason, plus the
/// cross-screen history badges (seen / generated / tracked-status) when there are any.
struct RankedRow: View {
    let ranked: RankedJob
    /// The job's history across Results, saved jobs, and the Tracker (Milestone S-C).
    var history: JobHistory = JobHistory()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ScoreBadge(score: ranked.score)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(ranked.listing.title).font(.headline)
                    // AI-suggested lead marker (v0.6.0 Milestone J) — set apart from verified postings.
                    if ranked.listing.isAISuggested {
                        FacetBadge(text: "AI-suggested", systemImage: "sparkles", tint: .purple)
                    }
                    ForEach(Array(history.facets.enumerated()), id: \.offset) { _, facet in
                        facetBadge(facet)
                    }
                }
                Text("\(ranked.listing.company) · \(ranked.listing.location)")
                    .font(.subheadline).foregroundStyle(.secondary)
                metaChips
                Text(ranked.match.reason)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    /// Work-type / employment-type chips for an enriched listing (v0.6.0 Milestone A-F).
    /// Omitted entirely when the listing has no such detail, so un-enriched rows are unchanged.
    @ViewBuilder private var metaChips: some View {
        let chips = PostingMetaBadge.badges(for: ranked.listing).filter {
            $0.kind == .workType || $0.kind == .employment
        }
        if !chips.isEmpty {
            HStack(spacing: 6) {
                ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                    FacetBadge(text: chip.text, systemImage: chip.systemImage, tint: .blue)
                }
            }
        }
    }

    @ViewBuilder private func facetBadge(_ facet: JobHistory.Facet) -> some View {
        switch facet {
        case .status(let status): StatusBadge(status: status)
        case .seen: FacetBadge(text: "Seen", systemImage: "eye", tint: .secondary)
        case .generated: FacetBadge(text: "Generated", systemImage: "doc.text", tint: .teal)
        }
    }
}

/// A circular 0–100 fit-score badge, coloured by band.
struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.headline.monospacedDigit())
            .frame(width: 44, height: 44)
            .background(Circle().fill(color.opacity(0.2)))
            .foregroundStyle(color)
    }

    private var color: Color {
        switch score {
        case 75...: .green
        case 50..<75: .orange
        default: .gray
        }
    }
}

#if DEBUG
#Preview {
    List(Preview.sampleRankedJobs) { RankedRow(ranked: $0) }
        .frame(width: 420)
}
#endif
