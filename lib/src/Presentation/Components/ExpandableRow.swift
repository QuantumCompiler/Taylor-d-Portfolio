//
//  ExpandableRow.swift
//  Taylor'd Portfolio
//
//  Presentation · Components — a disclosure whose whole header row toggles.
//

import SwiftUI

/// A collapsible section whose **entire header row** (chevron + label) toggles its content —
/// unlike SwiftUI's `DisclosureGroup`, which only responds to a click on the caret. The header
/// shows the pointing-hand cursor, matching the rest of the app's clickable affordances.
///
/// Two ways to drive it:
/// - **Self-managed** — `ExpandableRow(initiallyExpanded:) { label } content: { … }` keeps its own
///   expansion state (the common case: local, per-row UI).
/// - **Caller-controlled** — `ExpandableRow(isExpanded: $flag) { … }` binds to external state, so a
///   view model can also open/close it (e.g. auto-expanding a recovery panel).
///
/// The expanded content is emitted as-is, so selectable text inside keeps its native I-beam —
/// only the header row carries the pointer cursor.
struct ExpandableRow<Label: View, Content: View>: View {
    @State private var localExpanded: Bool
    private let externalBinding: Binding<Bool>?
    private let label: Label
    private let content: Content

    /// Self-managed expansion state.
    init(initiallyExpanded: Bool = false,
         @ViewBuilder label: () -> Label,
         @ViewBuilder content: () -> Content) {
        _localExpanded = State(initialValue: initiallyExpanded)
        externalBinding = nil
        self.label = label()
        self.content = content()
    }

    /// Caller-controlled expansion (so external state can also open/close it).
    init(isExpanded: Binding<Bool>,
         @ViewBuilder label: () -> Label,
         @ViewBuilder content: () -> Content) {
        _localExpanded = State(initialValue: isExpanded.wrappedValue)
        externalBinding = isExpanded
        self.label = label()
        self.content = content()
    }

    private var isExpanded: Bool { externalBinding?.wrappedValue ?? localExpanded }

    private func toggle() {
        withAnimation(.easeInOut(duration: 0.15)) {
            if let externalBinding { externalBinding.wrappedValue.toggle() }
            else { localExpanded.toggle() }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                label
                Spacer(minLength: 0)
            }
            // The whole row is the tap target (not just the caret).
            .contentShape(Rectangle())
            .onTapGesture { toggle() }
            .clickableCursor()

            if isExpanded {
                content
            }
        }
    }
}
