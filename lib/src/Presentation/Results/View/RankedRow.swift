//
//  RankedRow.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · View — one row in the ranked results list.
//

import SwiftUI

/// A single ranked job: score badge + title/company + the model's reason.
struct RankedRow: View {
    let ranked: RankedJob

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ScoreBadge(score: ranked.score)
            VStack(alignment: .leading, spacing: 2) {
                Text(ranked.listing.title).font(.headline)
                Text("\(ranked.listing.company) · \(ranked.listing.location)")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(ranked.match.reason)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

/// A circular 0–100 fit-score badge, coloured by band.
private struct ScoreBadge: View {
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
