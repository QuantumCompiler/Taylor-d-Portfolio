//
//  InlineEmptyState.swift
//  Taylor'd Portfolio
//
//  Presentation · Components — a left-aligned empty state for scrolling screens.
//

import SwiftUI

/// A compact, left-aligned "nothing here yet" placeholder for use **inside a scrolling
/// screen** (Portfolio / Search sub-views), where the centered `ContentUnavailableView`
/// doesn't sit right. List-based screens (Results / Tracker) keep `ContentUnavailableView`.
struct InlineEmptyState: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 24)
    }
}
