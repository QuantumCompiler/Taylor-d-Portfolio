//
//  StatusBadge.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · View — a small application-status pill.
//

import SwiftUI

/// A compact badge showing an application's stage and (when set) its date, e.g.
/// "Applied · Jun 12". Reused on result rows and the Tracker list.
struct StatusBadge: View {
    let status: ApplicationStatus

    var body: some View {
        Text(label)
            .font(.caption2).bold()
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        if let date = status.currentDate {
            return "\(status.stage.label) · \(date.formatted(.dateTime.month(.abbreviated).day()))"
        }
        return status.stage.label
    }

    private var color: Color {
        switch status.stage {
        case .saved: .gray
        case .applied: .blue
        case .interviewing: .purple
        case .offer, .accepted: .green
        case .rejected, .withdrawn, .declined: .gray
        }
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: 6) {
        StatusBadge(status: ApplicationStatus(stage: .applied, appliedDate: .now))
        StatusBadge(status: ApplicationStatus(stage: .interviewing, interviewDate: .now))
        StatusBadge(status: ApplicationStatus(stage: .offer, offerDate: .now))
        StatusBadge(status: ApplicationStatus(stage: .rejected, closedDate: .now))
    }
    .padding()
}
#endif
