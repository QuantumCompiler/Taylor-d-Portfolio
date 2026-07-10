//
//  SearchViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Search · ViewModel
//

import Foundation
import Observation

/// Drives the Search screen: collects one or more role titles (chips) plus a shared
/// location and salary floor, and runs a merged multi-title search + ranking.
///
/// Titles are seeded from the loaded profile's `targetTitles`. The user builds their
/// own persisted library of **common role titles** by long-pressing a chip; those
/// appear as toggle-select tiles (tapping one includes it in the search too) and
/// survive relaunch via ``RoleTitleStore``. `adzunaConfigured` reflects whether the
/// build baked in Adzuna credentials (Milestone K); when it didn't, search is disabled
/// with a clear "unavailable in this build" banner.
@MainActor
@Observable
final class SearchViewModel {
    /// Confirmed role-title chips to search. Edited via ``addTitle(_:)`` /
    /// ``removeTitle(_:)`` in the UI; settable for seeding and tests.
    var titles: [String] = []
    /// The in-progress title text (also searched if the user hits Search without adding it).
    var titleInput: String = ""
    var location: String = ""
    /// Selected salary floor (a preset bracket), or `nil` for "Any".
    var salaryMin: Int?

    /// A job-posting URL to generate from directly (Milestone M-A).
    var postingURL: String = ""
    /// Pasted posting text — the fallback when a page can't be fetched.
    var pastedPosting: String = ""
    private(set) var isFetchingLink = false
    /// A failure from the link-fetch / pasted-text flow. Kept separate from
    /// ``errorMessage`` (the keyword-search error) so the Search screen can show it
    /// **next to the Fetch action**, not next to the Search button.
    private(set) var linkErrorMessage: String?

    /// The user's persisted library of common role titles, shown as toggle tiles.
    private(set) var commonRoleTitles: [String] = []
    /// Which common role titles are toggled on (searched alongside the chips).
    private(set) var selectedCommonTitles: [String] = []

    /// The saved-profile library the user can search against, newest first.
    private(set) var savedProfiles: [SavedProfile] = []

    var profile: CandidateProfile? {
        didSet {
            guard profile != oldValue else { return }
            // Seed chips from the profile's target titles the first time one loads.
            if titles.isEmpty {
                titles = Array(suggestions.seededTitles(for: profile).prefix(3))
            }
        }
    }

    private(set) var results: [RankedJob] = []
    private(set) var isSearching = false
    private(set) var errorMessage: String?
    /// A soft, non-fatal note (e.g. one title's search failed but others succeeded).
    private(set) var warningMessage: String?

    /// Whether this build has baked Adzuna credentials. When `false`, search can't run.
    let adzunaConfigured: Bool

    private let searchAndRank: SearchAndRankUseCase
    private let suggestions: SuggestionProvider
    private let roleTitleStore: RoleTitleStore
    private let fetchPosting: FetchPostingUseCase?
    private let saveResults: SaveResultsUseCase?
    private let loadProfiles: LoadProfilesUseCase?

    init(
        searchAndRank: SearchAndRankUseCase,
        suggestions: SuggestionProvider = SuggestionProvider(),
        roleTitleStore: RoleTitleStore,
        fetchPosting: FetchPostingUseCase? = nil,
        saveResults: SaveResultsUseCase? = nil,
        loadProfiles: LoadProfilesUseCase? = nil,
        adzunaConfigured: Bool = true
    ) {
        self.searchAndRank = searchAndRank
        self.suggestions = suggestions
        self.roleTitleStore = roleTitleStore
        self.fetchPosting = fetchPosting
        self.saveResults = saveResults
        self.loadProfiles = loadProfiles
        self.adzunaConfigured = adzunaConfigured
        self.commonRoleTitles = roleTitleStore.load()
    }

    // MARK: Saved-profile selection

    /// Whether the saved-profile picker should be offered in this build.
    var supportsSavedProfiles: Bool { loadProfiles != nil }

    /// The id of the saved profile matching the active `profile`, or `nil` when the
    /// active profile isn't one of the saved ones (e.g. a freshly-built, unsaved one).
    /// Drives the profile `Picker`; setting it selects that saved profile.
    var selectedProfileID: String? {
        get { savedProfiles.first { $0.profile == profile }?.id }
        set { selectSavedProfile(newValue) }
    }

    /// Loads the saved-profile library (call on appear). No-op when unavailable.
    func reloadProfiles() async {
        guard let loadProfiles else { return }
        savedProfiles = (try? await loadProfiles()) ?? savedProfiles
    }

    /// Sets the active search profile to the saved profile with `id` (nil is ignored,
    /// so the picker can't clear an existing selection to "nothing").
    func selectSavedProfile(_ id: String?) {
        guard let id, let saved = savedProfiles.first(where: { $0.id == id }) else { return }
        profile = saved.profile
    }

    /// Persists the current results (best-effort — a persistence failure never breaks
    /// the search/fetch the user just ran).
    private func persistResults() async {
        guard let saveResults, !results.isEmpty else { return }
        try? await saveResults(results)
    }

    /// Whether the "generate from a link" affordance is wired in this build.
    var canUseLink: Bool { fetchPosting != nil }

    var hasProfile: Bool { profile != nil }

    /// All titles that a search would run: the chips, the toggled-on common titles, and
    /// the in-progress input, de-duplicated case-insensitively.
    var effectiveTitles: [String] {
        var seen = Set<String>()
        var result = [String]()
        for title in titles + selectedCommonTitles + [titleInput] {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { continue }
            result.append(trimmed)
        }
        return result
    }

    var locationOptions: [String] { suggestions.locationSuggestions() }
    var salaryPresets: [Int] { SuggestionProvider.salaryPresets }

    /// A build-level banner shown when search is unavailable because credentials
    /// weren't baked in. Distinct from `errorMessage`, which reports run failures.
    var unavailableMessage: String? {
        adzunaConfigured
            ? nil
            : "Search is unavailable in this build — Adzuna credentials weren't configured when it was built."
    }

    var canSearch: Bool {
        adzunaConfigured && hasProfile && !effectiveTitles.isEmpty && !isSearching
    }

    // MARK: Chip editing

    /// Adds `title` (or the current input when `title` is nil) as a chip.
    func addTitle(_ title: String? = nil) {
        let raw = (title ?? titleInput).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        if !titles.contains(where: { $0.lowercased() == raw.lowercased() }) {
            titles.append(raw)
        }
        titleInput = ""
    }

    func removeTitle(_ title: String) {
        titles.removeAll { $0 == title }
    }

    // MARK: Common role titles (persisted library)

    /// Saves a title into the persisted common-role-titles library (long-press a chip).
    func saveAsCommonRoleTitle(_ title: String) {
        let raw = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty,
              !commonRoleTitles.contains(where: { $0.lowercased() == raw.lowercased() })
        else { return }
        commonRoleTitles.append(raw)
        roleTitleStore.save(commonRoleTitles)
    }

    /// Removes a title from the persisted library (the tile's "x"), de-selecting it too.
    func removeCommonRoleTitle(_ title: String) {
        commonRoleTitles.removeAll { $0.lowercased() == title.lowercased() }
        selectedCommonTitles.removeAll { $0.lowercased() == title.lowercased() }
        roleTitleStore.save(commonRoleTitles)
    }

    /// Whether a common role title is toggled on (and thus included in the search).
    func isCommonTitleSelected(_ title: String) -> Bool {
        selectedCommonTitles.contains { $0.lowercased() == title.lowercased() }
    }

    /// Toggles a common role title on/off for the search.
    func toggleCommonTitle(_ title: String) {
        if let index = selectedCommonTitles.firstIndex(where: { $0.lowercased() == title.lowercased() }) {
            selectedCommonTitles.remove(at: index)
        } else {
            selectedCommonTitles.append(title)
        }
    }

    /// Whether `title` is already in the persisted library (drives the chip's affordance).
    func isCommonRoleTitle(_ title: String) -> Bool {
        commonRoleTitles.contains { $0.lowercased() == title.lowercased() }
    }

    // MARK: From a link / pasted text (M-A)

    /// Whether the "Fetch" action can run (link wired, profile present, URL entered).
    var canFetchLink: Bool {
        canUseLink && hasProfile && !isFetchingLink
            && !postingURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Fetches a posting from `postingURL`, ranks it, and pushes it into the results
    /// flow. Independent of Adzuna (uses HTTP + the LLM, not the job search API).
    func fetchFromLink() async {
        guard let fetchPosting else { return }
        guard let profile else {
            linkErrorMessage = "Build your profile on the Portfolio tab first."
            return
        }
        let raw = postingURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: raw), url.scheme == "http" || url.scheme == "https" else {
            linkErrorMessage = "Enter a valid http(s) link to a job posting."
            return
        }
        isFetchingLink = true
        linkErrorMessage = nil
        warningMessage = nil
        defer { isFetchingLink = false }
        do {
            results = [try await fetchPosting(url: url, profile: profile)]
            await persistResults()
        } catch is JobPostingSourceError {
            linkErrorMessage = "Couldn't read that posting — the page may need a login or block automated access. "
                + "Paste the posting text below and use “Generate from pasted text” instead."
        } catch {
            linkErrorMessage = Self.message(for: error)
        }
    }

    /// Extracts a posting from `pastedPosting` (the fallback for un-fetchable pages),
    /// ranks it, and pushes it into the results flow.
    func generateFromPastedText() async {
        guard let fetchPosting else { return }
        guard let profile else {
            linkErrorMessage = "Build your profile on the Portfolio tab first."
            return
        }
        let text = pastedPosting.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            linkErrorMessage = "Paste the job posting text first."
            return
        }
        isFetchingLink = true
        linkErrorMessage = nil
        warningMessage = nil
        defer { isFetchingLink = false }
        do {
            let sourceURL = URL(string: postingURL.trimmingCharacters(in: .whitespacesAndNewlines))
            results = [try await fetchPosting(pastedText: text, sourceURL: sourceURL, profile: profile)]
            await persistResults()
        } catch is JobPostingSourceError {
            linkErrorMessage = "That didn't look like a job posting — make sure you pasted the full description."
        } catch {
            linkErrorMessage = Self.message(for: error)
        }
    }

    // MARK: Search

    func search() async {
        guard adzunaConfigured else {
            errorMessage = unavailableMessage
            return
        }
        guard hasProfile, let profile else {
            errorMessage = "Build your profile on the Portfolio tab first."
            return
        }
        guard canSearch else { return }

        let request = JobSearchRequest(
            titles: effectiveTitles,
            location: location.isEmpty ? nil : location,
            salaryMin: salaryMin.map(Double.init)
        )
        isSearching = true
        errorMessage = nil
        warningMessage = nil
        defer { isSearching = false }
        do {
            let output = try await searchAndRank(request: request, profile: profile)
            results = output.rankedJobs
            warningMessage = output.failedTitles.isEmpty
                ? nil
                : "Couldn't search: \(output.failedTitles.joined(separator: ", "))."
            await persistResults()
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    /// Maps a search/ranking failure to an actionable message rather than a generic one.
    /// The error type tells us which stage failed: HTTP/URL/decoding → the Adzuna search;
    /// Foundation-model / Claude / provider errors → the LLM ranking step.
    static func message(for error: Error) -> String {
        switch error {
        // MARK: Search (Adzuna) failures
        case let HTTPError.status(code, _):
            switch code {
            case 401, 403:
                return "The job service rejected the request — the Adzuna API credentials appear to be invalid."
            case 429:
                return "Too many searches too quickly. Wait a moment and try again."
            case 500...:
                return "The job service is having problems (error \(code)). Try again shortly."
            default:
                return "The job service returned an error (code \(code))."
            }
        case HTTPError.nonHTTPResponse:
            return "Got an unexpected response from the job service. Try again."
        case is DecodingError:
            return "Couldn't read the job service's response — the data format may have changed."
        case let urlError as URLError:
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .timedOut:
                return "Couldn't reach the job service. Check your internet connection and try again."
            default:
                return "Network error while searching (\(urlError.code.rawValue)). Try again."
            }

        // MARK: Ranking (LLM engine) failures
        case is FoundationModelsError:
            return "The on-device model isn't available for ranking. Turn on Apple Intelligence in "
                + "System Settings › Apple Intelligence & Siri, then try again."
        case ClaudeProcessError.launchFailed:
            return "Couldn't launch the Claude CLI to rank jobs. A sandboxed build can't run it — "
                + "enable Apple Intelligence to rank on-device, or use an unsandboxed build for the Claude engine."
        case let ClaudeProcessError.nonZeroExit(_, message):
            return "The Claude CLI failed while ranking\(message.isEmpty ? "." : ": \(message)")"
        case ClaudeProcessError.claudeReportedError, ClaudeProcessError.emptyOutput, ClaudeProcessError.decodingFailed:
            return "The Claude CLI returned an unexpected result while ranking. Try again."
        case LLMProviderError.decodingFailed:
            return "The AI engine returned a response we couldn't parse. Try again."
        case LLMProviderError.noProviderAvailable:
            return "No AI engine is available to rank jobs. Enable Apple Intelligence, or choose Claude in Settings."

        default:
            return "Search failed: \(error.localizedDescription)"
        }
    }
}
