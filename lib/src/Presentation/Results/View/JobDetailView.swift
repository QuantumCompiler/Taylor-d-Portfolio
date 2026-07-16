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
    /// Loads a previously-generated kit so the Tracker footer can offer **View** alongside
    /// Generate when materials already exist (v0.5.0 Milestone A).
    var loadApplication: LoadApplicationUseCase? = nil
    /// Whether the horizontal save/dismiss swipe is enabled. Off when hosted in a window
    /// (v0.5.0 Milestone B) — a window has no card to swipe.
    var allowsSwipe: Bool = true
    /// Re-rank (and optionally re-enrich) this result against a chosen profile (v0.6.0 C).
    /// When nil, the "Regenerate result" control is hidden.
    var regenerateResult: RegenerateResultUseCase? = nil
    /// Loads the saved profiles the re-rank profile picker offers (v0.6.0 C).
    var loadProfiles: LoadProfilesUseCase? = nil
    /// Called after this view mutates shared persistence (status set, materials generated,
    /// saved), so a hosting window can signal the lists to reload (v0.5.0 Milestone B).
    var onMutate: (() -> Void)? = nil
    /// Called with the re-ranked result after "Regenerate result" (v0.6.0 Milestone C), so a
    /// hosting window can replace the matching row in the main-window Results list (which isn't
    /// re-read wholesale). `onMutate` still fires for the generic reload.
    var onRegenerated: ((RankedJob) -> Void)? = nil
    /// Opens the Application window (v0.5.0 Milestone B-C). Supplied by the hosting window;
    /// when nil (e.g. previews) the View/Generate buttons do nothing.
    var onOpenApplication: (() -> Void)? = nil
    /// Picking a profile in the detail's picker **loads** it (sets the session profile +
    /// grounding), so generation can proceed here without a trip to the Portfolio tab.
    var onSelectProfile: ((SavedProfile) -> Void)? = nil
    /// A monotonically-increasing signal from the hosting window; a change re-checks whether
    /// materials now exist (e.g. after the Application window generated) — v0.5.0 B-C.
    var refreshSignal: Int = 0

    @Environment(\.dismiss) private var dismiss
    @State private var status: ApplicationStatus?
    @State private var dragOffset: CGFloat = 0
    /// Whether a generated kit is already saved for this job (drives the View vs Generate footer).
    @State private var hasGeneratedMaterials = false
    // Regenerate-result state (v0.6.0 Milestone C).
    /// The freshly re-ranked result after "Regenerate result", if any — it overrides `ranked`
    /// for display so the score/reason/detail update in place.
    @State private var displayRanked: RankedJob?
    @State private var regenProfiles: [SavedProfile] = []
    @State private var regenProfileID: String?
    @State private var regenContext = ""
    @State private var isRegenerating = false
    @State private var regenError: String?

    /// The result currently shown — the re-ranked one after "Regenerate result", else the one
    /// passed in (v0.6.0 Milestone C).
    private var shown: RankedJob { displayRanked ?? ranked }
    private var listing: JobListing { shown.listing }
    /// Only the Results context (where a save action is supplied) is swipeable, and only
    /// when swiping is allowed (off in a window — v0.5.0 Milestone B).
    private var isSwipeable: Bool { onSaveToTracker != nil && allowsSwipe }
    private static let swipeThreshold: CGFloat = 120

    var body: some View {
        card
            .offset(x: isSwipeable ? dragOffset : 0)
            .overlay(alignment: dragOffset >= 0 ? .leading : .trailing) { swipeHint }
            .gesture(swipeGesture, isEnabled: isSwipeable)
            .trackpadSwipe(
                isEnabled: isSwipeable,
                onChanged: { dragOffset = $0 },
                onEnded: { endSwipe(translation: $0) }
            )
            .padding(24)
            .frame(minWidth: 540, minHeight: 500)
            .task { await loadDetailState() }
            // Re-check for saved materials whenever the hosting window signals a change (e.g.
            // the Application window generated), so the View button appears live (v0.5.0 B-C).
            .onChange(of: refreshSignal) { _, _ in Task { await refreshHasMaterials() } }
    }

    // MARK: Detail state loading

    private func loadDetailState() async {
        if let loadStatus {
            status = (try? await loadStatus(forJobID: ranked.id)) ?? nil
        }
        if let loadProfiles {
            regenProfiles = (try? await loadProfiles()) ?? []
        }
        await refreshHasMaterials()
    }

    /// Refreshes whether a generated kit exists for this job (Tracker context only).
    private func refreshHasMaterials() async {
        guard let loadApplication else { hasGeneratedMaterials = false; return }
        hasGeneratedMaterials = ((try? await loadApplication(forJobID: ranked.id)) ?? nil) != nil
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if listing.isAISuggested { aiSuggestedBanner }
                    if markStatus != nil { statusSection }
                    metaBadges
                    matchSection
                    if let salary = listing.salary, let text = SalaryFormatter.text(salary) {
                        labeledSection("Salary") { Text(text).font(.callout) }
                    }
                    descriptionSection
                    postingDetailSection
                }
            }
            Divider()
            footer
        }
    }

    // MARK: Swipe (Results context, Milestone V-C)

    /// Mouse click-drag fallback (trackpad users get the no-click `.trackpadSwipe`).
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { dragOffset = $0.translation.width }
            .onEnded { endSwipe(translation: $0.translation.width) }
    }

    /// Resolves a finished swipe (from either input) into save / dismiss / spring-back.
    private func endSwipe(translation: CGFloat) {
        switch SwipeOutcome.resolve(translation: translation, threshold: Self.swipeThreshold) {
        case .save: onSaveToTracker?(); dismiss()
        case .dismiss: dismiss()
        case .none: withAnimation(.spring(duration: 0.25)) { dragOffset = 0 }
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
                // "Set status" already offers every settable stage (incl. Applied) with the
                // same auto-date-stamp, so the dedicated "Mark as applied" button was
                // redundant and was removed (v0.5.0 Milestone C).
                Menu("Set status") {
                    ForEach(ApplicationStage.settable, id: \.self) { stage in
                        Button(stage.label) { mark(stage) }
                    }
                }
                .fixedSize()
                .clickableCursor()
            }
        }
    }

    private func mark(_ stage: ApplicationStage) {
        guard let markStatus else { return }
        Task {
            status = try? await markStatus(jobID: ranked.id, stage: stage)
            onMutate?()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ScoreBadge(score: shown.score)
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
        labeledSection("Why this ranked \(shown.score)") {
            VStack(alignment: .leading, spacing: 10) {
                if !shown.match.reason.isEmpty {
                    Text(shown.match.reason).font(.callout)
                }
                if !shown.match.matchedSkills.isEmpty {
                    skillRow("Matched", shown.match.matchedSkills, tint: .green)
                }
                if !shown.match.missingSkills.isEmpty {
                    skillRow("Missing", shown.match.missingSkills, tint: .orange)
                }
                regenerateControl
            }
        }
    }

    // MARK: Regenerate result (v0.6.0 Milestone C)

    /// A compact "re-rank this result" control: an optional profile picker + a steering context
    /// box + the Regenerate button. Hidden unless the use case is wired. Re-assessing fit is
    /// honest — the score may rise or fall — and it backfills posting detail on legacy entries.
    @ViewBuilder private var regenerateControl: some View {
        if let regenerateResult {
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                if !regenProfiles.isEmpty {
                    Picker("Profile", selection: $regenProfileID) {
                        Text("Current profile").tag(String?.none)
                        ForEach(regenProfiles) { saved in Text(saved.name).tag(Optional(saved.id)) }
                    }
                    .labelsHidden()
                    .clickableCursor()
                    // Picking a saved profile loads it session-wide, so Generate/Regenerate both
                    // use it — no need to go to the Portfolio tab (the "Current profile" option
                    // keeps whatever was already loaded).
                    .onChange(of: regenProfileID) { _, newID in
                        guard let newID, let saved = regenProfiles.first(where: { $0.id == newID }) else { return }
                        onSelectProfile?(saved)
                    }
                }
                TextField("Optional: steer the re-rank (e.g. weight my Go backend experience)",
                          text: $regenContext, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
                    .clickableCursor()
                HStack(spacing: 8) {
                    Button("Regenerate result") { regenerate(using: regenerateResult) }
                        .disabled(isRegenerating || chosenRegenProfile == nil)
                        .clickableCursor()
                    if isRegenerating { ProgressView().controlSize(.small) }
                }
                if let regenError {
                    Text(regenError).font(.caption).foregroundStyle(.orange).textSelection(.enabled)
                }
                Text("Re-assesses fit honestly (may raise or lower the score) and backfills posting "
                     + "detail. Steers emphasis, never facts.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    /// The profile to re-rank against: the picked saved profile, or the ambient loaded one.
    private var chosenRegenProfile: CandidateProfile? {
        if let id = regenProfileID, let picked = regenProfiles.first(where: { $0.id == id }) {
            return picked.profile
        }
        return profile
    }

    private func regenerate(using useCase: RegenerateResultUseCase) {
        guard let chosen = chosenRegenProfile else { return }
        isRegenerating = true
        regenError = nil
        Task {
            defer { isRegenerating = false }
            do {
                let refreshed = try await useCase(shown, profile: chosen, instruction: regenContext)
                displayRanked = refreshed
                onRegenerated?(refreshed)   // replace the matching Results row with the new score
                onMutate?()                 // refresh the lists + main window (score/badges changed)
            } catch {
                regenError = "Couldn't re-rank this result. Try again.\n\n(\(String(describing: error)))"
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

    // MARK: AI-suggested lead (v0.6.0 Milestone J)

    /// A prominent notice that this is an AI-suggested lead, not a verified posting — the one hard
    /// rule for the LLM job source is that the user is never misled into treating it as confirmed.
    private var aiSuggestedBanner: some View {
        Label(
            "AI-suggested lead — not a verified posting. Confirm the role and company before applying.",
            systemImage: "sparkles"
        )
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Richer posting detail (v0.6.0 Milestone A-F)

    /// At-a-glance chips (work type, employment type, posted date, category) — shown only when
    /// the listing carries them, so an un-enriched posting looks exactly as before.
    @ViewBuilder private var metaBadges: some View {
        let badges = PostingMetaBadge.badges(for: listing)
        if !badges.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                        FacetBadge(text: badge.text, systemImage: badge.systemImage, tint: tint(for: badge.kind))
                    }
                }
            }
        }
    }

    private func tint(for kind: PostingMetaBadge.Kind) -> Color {
        switch kind {
        case .workType:   return .blue
        case .employment: return .indigo
        case .posted:     return .secondary
        case .category:   return .secondary
        }
    }

    /// The enriched posting structure as collapsible sections — only the non-empty ones,
    /// and the whole block is omitted when there's nothing enriched.
    @ViewBuilder private var postingDetailSection: some View {
        if let details = listing.details, details.hasContent {
            labeledSection("Posting details") {
                VStack(alignment: .leading, spacing: 12) {
                    detailDisclosure("About the role", text: details.aboutRole)
                    detailDisclosure("About the company", text: details.aboutCompany)
                    detailDisclosure("Qualifications", list: details.qualifications)
                    detailDisclosure("Responsibilities", list: details.responsibilities)
                    detailDisclosure("Nice to have", list: details.niceToHaves)
                    detailDisclosure("Benefits", list: details.benefits)
                }
            }
        }
    }

    @ViewBuilder private func detailDisclosure(_ title: String, text: String) -> some View {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            ExpandableRow {
                Text(title).font(.subheadline.weight(.semibold))
            } content: {
                Text(trimmed)
                    .font(.callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private func detailDisclosure(_ title: String, list: [String]) -> some View {
        if !list.isEmpty {
            ExpandableRow {
                Text(title).font(.subheadline.weight(.semibold))
            } content: {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(list.enumerated()), id: \.offset) { _, item in
                        Text("• \(item)")
                            .font(.callout)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: Description

    @ViewBuilder
    private var descriptionSection: some View {
        labeledSection("Description") {
            if let full = listing.fullDescription,
               !full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // The recovered full posting is clean markdown (v0.6.0 Milestone E) — render it
                // styled (headings / bullets / bold), not as raw markup.
                MarkdownText(markdown: full)
            } else {
                // The Adzuna snippet is HTML/plain text — strip tags and show it plainly.
                let text = HTMLStripper.plainText(listing.description)
                Text(text.isEmpty ? "No description provided." : text)
                    .font(.callout)
                    .foregroundStyle(text.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            if let url = listing.url {
                Link(destination: url) {
                    // An AI lead's URL is a web *search* for the role, not a confirmed posting.
                    Label(listing.isAISuggested ? "Search for this role" : "View original posting",
                          systemImage: listing.isAISuggested ? "magnifyingglass" : "arrow.up.right.square")
                }
                .clickableCursor()
            }
            Spacer()
            switch JobDetailFooter.resolve(
                canGenerate: canGenerate,
                hasGeneratedMaterials: hasGeneratedMaterials,
                canSaveToTracker: onSaveToTracker != nil
            ) {
            case .none:
                EmptyView()
            case .saveToTracker:
                // Results context: no generation — read the posting and choose to save.
                Button { onSaveToTracker?(); dismiss() } label: {
                    Label("Save to Tracker", systemImage: "bookmark")
                }
                .buttonStyle(.borderedProminent)
                .clickableCursor()
            case .generate:
                // Tracker context, nothing generated yet (Milestone V-D). Opens the
                // Application window where the user sets options and presses Generate.
                if profile == nil {
                    Text(regenProfiles.isEmpty
                         ? "Load a profile on the Portfolio tab to generate."
                         : "Pick a profile above to generate.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Generate application") { openApplication() }
                    .buttonStyle(.borderedProminent)
                    .disabled(profile == nil)
                    .help(profile == nil ? "Select a profile in the picker above to enable generation." : "")
                    .clickableCursor()
            case .view:
                // Tracker context with saved materials (v0.5.0 Milestone A): open the
                // Application window to view them (and regenerate there, with options).
                Button("View application") { openApplication() }
                    .buttonStyle(.borderedProminent)
                    .disabled(profile == nil)
                    .clickableCursor()
            }
        }
    }

    /// Opens the Application window (via the hosting window).
    private func openApplication() {
        onOpenApplication?()
    }

    private func labeledSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Which action(s) the job-detail footer offers, resolved from the view's context.
/// Pure so it can be unit-tested without the SwiftUI view (v0.5.0 Milestone A).
nonisolated enum JobDetailFooter: Equatable {
    /// No primary action (e.g. Results context with no save action wired).
    case none
    /// Results context: save the posting to the Tracker.
    case saveToTracker
    /// Tracker context, nothing generated yet: a single Generate action.
    case generate
    /// Tracker context with saved materials: a View action (opens the Application window).
    case view

    static func resolve(canGenerate: Bool, hasGeneratedMaterials: Bool, canSaveToTracker: Bool) -> JobDetailFooter {
        if canGenerate {
            return hasGeneratedMaterials ? .view : .generate
        }
        return canSaveToTracker ? .saveToTracker : .none
    }
}

#if DEBUG
#Preview {
    JobDetailView(
        ranked: Preview.sampleRankedJobs[0],
        profile: Preview.sampleProfile
    )
}
#endif
