//
//  ListFilterBar.swift
//  Taylor'd Portfolio
//
//  Presentation · Components — the shared filter bar for the two list tabs (v0.6.2 Milestone C).
//

import SwiftUI

/// The live filter controls over a `ResultsFilter`, shared by **Results** and the **Tracker**.
///
/// Extracted from `ResultsView.filterBar` (Milestone W) when the Tracker gained the same filter
/// (v0.6.2 Milestone C) — one bar rather than two that drift apart, which is the point of giving
/// both tabs the same capability. The owning view supplies the binding and the option lists,
/// since those come from that tab's own view model.
///
/// The `trackedStatus` facet is deliberately **not** exposed: it's moot in the Tracker (every row
/// there is tracked) and in Results (tracked jobs left that list in v0.4.1 Milestone C).
struct ListFilterBar: View {
    @Binding var filter: ResultsFilter
    let locationOptions: [String]
    let companyOptions: [String]
    /// Rows currently shown / rows before filtering — the "Showing X of Y" readout.
    let visibleCount: Int
    let totalCount: Int
    let onClear: () -> Void

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Minimum rank").frame(width: 120, alignment: .leading).foregroundStyle(.secondary)
                    Slider(
                        value: Binding(
                            get: { Double(filter.minScore ?? 0) },
                            set: { filter.minScore = $0 >= 1 ? Int($0) : nil }
                        ),
                        in: 0...100, step: 5
                    ).frame(maxWidth: 200).clickableCursor()
                    Text(filter.minScore.map { "\($0)+" } ?? "Any").monospacedDigit()
                }
                field("Keywords") {
                    TextField("Any", text: $filter.keywords).textFieldStyle(.roundedBorder).frame(maxWidth: 220)
                }
                field("Location") {
                    optionPicker(selection: $filter.location, options: locationOptions)
                }
                field("Company") {
                    optionPicker(selection: $filter.company, options: companyOptions)
                }
                field("Min salary") {
                    // Bounded parse + display (v0.7.1 Milestone H): a 19+ digit entry used to
                    // store ~1e19, and the display's `Int` conversion trapped on the next render
                    // — in both Results and the Tracker, since this bar is shared.
                    TextField("Any", text: Binding(
                        get: { ResultsFilter.salaryDisplay(filter.salaryMin) },
                        set: { filter.salaryMin = ResultsFilter.salaryInput($0) }
                    )).textFieldStyle(.roundedBorder).frame(maxWidth: 140)
                }
            }
            .padding(.top, 6)
        } label: {
            HStack {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                Spacer()
                Text("Showing \(visibleCount) of \(totalCount)")
                    .font(.caption).foregroundStyle(.secondary)
                if filter.isActive {
                    Button("Clear", action: onClear).font(.caption).clickableCursor()
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private func field<Controls: View>(_ label: String, @ViewBuilder controls: () -> Controls) -> some View {
        HStack(spacing: 8) {
            Text(label).frame(width: 120, alignment: .leading).foregroundStyle(.secondary)
            controls()
            Spacer(minLength: 0)
        }
    }

    /// A picker over `options` (plus "Any") bound to an optional string.
    private func optionPicker(selection: Binding<String?>, options: [String]) -> some View {
        Picker("", selection: Binding(
            get: { selection.wrappedValue ?? "" },
            set: { selection.wrappedValue = $0.isEmpty ? nil : $0 }
        )) {
            Text("Any").tag("")
            ForEach(options, id: \.self) { Text($0).tag($0) }
        }
        .labelsHidden().fixedSize().clickableCursor()
    }
}

/// The distinct, trimmed, case-insensitively-deduped, sorted values behind a filter's
/// location / company pickers — shared by both list view models (v0.6.2 Milestone C).
enum ListFilterOptions {
    static func distinct(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result = [String]()
        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { continue }
            result.append(trimmed)
        }
        return result.sorted()
    }
}
