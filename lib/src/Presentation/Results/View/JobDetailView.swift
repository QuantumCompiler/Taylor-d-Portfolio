//
//  JobDetailView.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · View — read-only detail for one ranked job.
//

import SwiftUI

/// A read-only detail screen for one `RankedJob`: the full job description, salary,
/// a link to the original posting, and the match score/reason + matched/missing
/// skills. The "Generate" button opens the existing `ApplicationSheet`.
///
/// Value-driven (no ViewModel of its own) — it just displays the `RankedJob` and
/// hands generation off to the shared `ApplicationViewModel`.
struct JobDetailView: View {
    let ranked: RankedJob
    let profile: CandidateProfile?
    let applicationViewModel: ApplicationViewModel
    var markStatus: MarkStatusUseCase? = nil
    var loadStatus: LoadStatusUseCase? = nil
    /// The candidate's real documents for grounded generation (Milestone T).
    var grounding: PortfolioGrounding? = nil
    /// Whether generation is offered here (Milestone V-D): **Tracker** context passes `true`
    /// (Generate button); **Results** context passes `false` (read + Save to Tracker only).
    var canGenerate: Bool = true
    /// Save-to-Tracker action, provided in the Results context (enables the footer button +
    /// the right-swipe). `nil` in the Tracker context.
    var onSaveToTracker: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var showingApplication = false
    @State private var status: ApplicationStatus?
    @State private var dragOffset: CGFloat = 0

    private var listing: JobListing { ranked.listing }
    /// Only the Results context (where a save action is supplied) is swipeable.
    private var isSwipeable: Bool { onSaveToTracker != nil }
    private static let swipeThreshold: CGFloat = 120

    var body: some View {
        card
            .offset(x: isSwipeable ? dragOffset : 0)
            .overlay(alignment: dragOffset >= 0 ? .leading : .trailing) { swipeHint }
            .gesture(swipeGesture, isEnabled: isSwipeable)
            .padding(24)
            .frame(minWidth: 540, minHeight: 500)
            .task {
                guard let loadStatus else { return }
                status = (try? await loadStatus(forJobID: ranked.id)) ?? nil
            }
            .sheet(isPresented: $showingApplication) {
                if let profile {
                    ApplicationSheet(viewModel: applicationViewModel, job: listing, profile: profile, grounding: grounding)
                }
            }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if markStatus != nil { statusSection }
                    matchSection
                    if let salary = listing.salary, let text = SalaryFormatter.text(salary) {
                        labeledSection("Salary") { Text(text).font(.callout) }
                    }
                    descriptionSection
                }
            }
            Divider()
            footer
        }
    }

    // MARK: Swipe (Results context, Milestone V-C)

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { dragOffset = $0.translation.width }
            .onEnded { value in
                switch SwipeOutcome.resolve(translation: value.translation.width, threshold: Self.swipeThreshold) {
                case .save: onSaveToTracker?(); dismiss()
                case .dismiss: dismiss()
                case .none: withAnimation(.spring(duration: 0.25)) { dragOffset = 0 }
                }
            }
    }

    /// A subtle hint that grows as the card is dragged: right ⇒ Save, left ⇒ Dismiss.
    @ViewBuilder private var swipeHint: some View {
        if isSwipeable, abs(dragOffset) > 20 {
            let saving = dragOffset > 0
            Label(saving ? "Save" : "Dismiss", systemImage: saving ? "bookmark.fill" : "xmark")
                .font(.headline)
                .foregroundStyle(saving ? Color.green : Color.secondary)
                .padding()
                .opacity(min(1, abs(dragOffset) / Self.swipeThreshold))
        }
    }

    // MARK: Application status

    private var statusSection: some View {
        labeledSection("Application status") {
            HStack {
                if let status {
                    StatusBadge(status: status)
                } else {
                    Text("Not tracked yet").font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                if status == nil {
                    Button("Mark as applied") { mark(.applied) }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                }
                Menu("Set status") {
                    ForEach(ApplicationStage.settable, id: \.self) { stage in
                        Button(stage.label) { mark(stage) }
                    }
                }
                .fixedSize()
            }
        }
    }

    private func mark(_ stage: ApplicationStage) {
        guard let markStatus else { return }
        Task { status = try? await markStatus(jobID: ranked.id, stage: stage) }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ScoreBadge(score: ranked.score)
            VStack(alignment: .leading, spacing: 2) {
                Text(listing.title).font(.title2.bold())
                Text("\(listing.company) · \(listing.location)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Done") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
    }

    // MARK: Match

    private var matchSection: some View {
        labeledSection("Why this ranked \(ranked.score)") {
            VStack(alignment: .leading, spacing: 10) {
                if !ranked.match.reason.isEmpty {
                    Text(ranked.match.reason).font(.callout)
                }
                if !ranked.match.matchedSkills.isEmpty {
                    skillRow("Matched", ranked.match.matchedSkills, tint: .green)
                }
                if !ranked.match.missingSkills.isEmpty {
                    skillRow("Missing", ranked.match.missingSkills, tint: .orange)
                }
            }
        }
    }

    private func skillRow(_ label: String, _ skills: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(skills, id: \.self) { skill in
                        Text(skill)
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(tint.opacity(0.18), in: Capsule())
                    }
                }
            }
        }
    }

    // MARK: Description

    private var descriptionSection: some View {
        labeledSection("Description") {
            let text = HTMLStripper.plainText(listing.description)
            Text(text.isEmpty ? "No description provided." : text)
                .font(.callout)
                .foregroundStyle(text.isEmpty ? .secondary : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            if let url = listing.url {
                Link(destination: url) {
                    Label("View original posting", systemImage: "arrow.up.right.square")
                }
            }
            Spacer()
            if canGenerate {
                // Tracker context: generate tailored materials (Milestone V-D).
                Button("Generate résumé & cover letter") { showingApplication = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(profile == nil)
            } else if let onSaveToTracker {
                // Results context: no generation — read the posting and choose to save.
                Button { onSaveToTracker(); dismiss() } label: {
                    Label("Save to Tracker", systemImage: "bookmark")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func labeledSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    JobDetailView(
        ranked: Preview.sampleRankedJobs[0],
        profile: Preview.sampleProfile,
        applicationViewModel: ApplicationViewModel(generateApplication: Preview.generateApplication)
    )
}
#endif
