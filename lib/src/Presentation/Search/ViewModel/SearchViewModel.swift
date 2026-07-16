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
    /// Typeable location — a custom value or a chosen preset (empty ⇒ "Anywhere").
    var location: String = ""
    /// Typeable minimum salary as text (empty/invalid ⇒ "Any"); parsed into `effectiveSalaryMin`.
    var salaryText: String = ""

    // MARK: Expanded, optional search parameters (Milestone U) — all default to today's behaviour.

    /// Optional employment-type filter (U-A).
    var positionType: PositionType?
    /// A best-effort target number of results as text (U-D); empty/invalid ⇒ no goal.
    var desiredResultText: String = ""
    /// Minimum match score 0–100 (U-E); 0 ⇒ no filter. A `Double` for the slider.
    var minimumScore: Double = 0

    /// The user's persisted saved locations + salary floors (U-B / U-C).
    private(set) var savedLocations: [String] = []
    private(set) var savedSalaries: [Int] = []

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

    /// The provider ids whose credentials resolve — the **available** set (Milestone H). A `var`
    /// so a Settings save refreshes it live. Search runs only providers that are both configured
    /// and selected.
    var configuredProviderIDs: Set<String>
    /// The provider ids the user has selected to query. Defaults to every registered provider.
    var selectedProviderIDs: Set<String>
    /// The registered providers, in order — drives the selector UI (Milestone H).
    let providers: [JobProviderDescriptor] = JobProviderRegistry.all

    /// The user's saved, re-runnable searches, newest first (Milestone R).
    private(set) var savedSearches: [SavedSearch] = []

    private let searchAndRank: SearchAndRankUseCase
    private let suggestions: SuggestionProvider
    private let roleTitleStore: RoleTitleStore
    private let locationStore: LocationStore?
    private let salaryPresetStore: SalaryPresetStore?
    private let fetchPosting: FetchPostingUseCase?
    private let saveResults: SaveResultsUseCase?
    private let loadProfiles: LoadProfilesUseCase?
    private let loadSavedJobs: LoadSavedJobsUseCase?
    private let saveSearch: SaveSearchUseCase?
    private let loadSavedSearches: LoadSavedSearchesUseCase?
    private let deleteSavedSearch: DeleteSavedSearchUseCase?

    init(
        searchAndRank: SearchAndRankUseCase,
        suggestions: SuggestionProvider = SuggestionProvider(),
        roleTitleStore: RoleTitleStore,
        locationStore: LocationStore? = nil,
        salaryPresetStore: SalaryPresetStore? = nil,
        fetchPosting: FetchPostingUseCase? = nil,
        saveResults: SaveResultsUseCase? = nil,
        loadProfiles: LoadProfilesUseCase? = nil,
        loadSavedJobs: LoadSavedJobsUseCase? = nil,
        saveSearch: SaveSearchUseCase? = nil,
        loadSavedSearches: LoadSavedSearchesUseCase? = nil,
        deleteSavedSearch: DeleteSavedSearchUseCase? = nil,
        configuredProviderIDs: Set<String> = Set(JobProviderRegistry.all.map(\.id))
    ) {
        self.searchAndRank = searchAndRank
        self.suggestions = suggestions
        self.roleTitleStore = roleTitleStore
        self.locationStore = locationStore
        self.salaryPresetStore = salaryPresetStore
        self.fetchPosting = fetchPosting
        self.saveResults = saveResults
        self.loadProfiles = loadProfiles
        self.loadSavedJobs = loadSavedJobs
        self.saveSearch = saveSearch
        self.loadSavedSearches = loadSavedSearches
        self.deleteSavedSearch = deleteSavedSearch
        self.configuredProviderIDs = configuredProviderIDs
        self.selectedProviderIDs = Set(JobProviderRegistry.all.map(\.id))
        self.commonRoleTitles = roleTitleStore.load()
        self.savedLocations = locationStore?.load() ?? []
        self.savedSalaries = salaryPresetStore?.load() ?? []
    }

    // MARK: Saved / re-runnable searches (Milestone R)

    /// Whether the saved-searches affordance is available in this build.
    var supportsSavedSearches: Bool { saveSearch != nil }

    /// Whether "Save this search" can run: wired, a profile is loaded, and ≥1 title set.
    var canSaveSearch: Bool {
        saveSearch != nil && hasProfile && !effectiveTitles.isEmpty && !isSearching
    }

    /// Loads the saved-search library (call on appear). No-op when unavailable.
    func reloadSavedSearches() async {
        guard let loadSavedSearches else { return }
        savedSearches = (try? await loadSavedSearches()) ?? savedSearches
    }

    /// Saves the current form as a re-runnable search, then refreshes the list.
    func saveCurrentSearch() async {
        guard let saveSearch, canSaveSearch else { return }
        _ = try? await saveSearch(buildRequest())
        await reloadSavedSearches()
    }

    /// Re-runs a saved search against the current profile: repopulates the form from the
    /// saved request, then runs it (reporting how many results are new since last time).
    func runSavedSearch(_ saved: SavedSearch) async {
        applyRequest(saved.request)
        guard !activeProviderIDs.isEmpty else { errorMessage = unavailableMessage; return }
        guard hasProfile else { errorMessage = "Build your profile on the Portfolio tab first."; return }
        await performSearch(saved.request, isRerun: true)
    }

    /// Deletes a saved search, then refreshes the list.
    func deleteSavedSearch(_ saved: SavedSearch) async {
        guard let deleteSavedSearch else { return }
        try? await deleteSavedSearch(id: saved.id)
        await reloadSavedSearches()
    }

    /// Repopulates the editable form fields from a saved request (so the UI reflects a re-run).
    private func applyRequest(_ request: JobSearchRequest) {
        titles = request.titles
        selectedCommonTitles = []
        titleInput = ""
        location = request.location ?? ""
        salaryText = request.salaryMin.map { String(Int($0)) } ?? ""
        positionType = request.positionType
        desiredResultText = request.desiredResultCount.map(String.init) ?? ""
        minimumScore = Double(request.minimumScore ?? 0)
        // Restore the saved provider selection (nil ⇒ all registered — a pre-H saved search).
        selectedProviderIDs = request.sources.map(Set.init) ?? Set(JobProviderRegistry.all.map(\.id))
    }

    // MARK: Expanded search parameters (Milestone U)

    /// All position-type options for the picker.
    var positionTypes: [PositionType] { PositionType.allCases }

    /// The parsed minimum-salary floor, or `nil` when the field is empty/non-numeric.
    var effectiveSalaryMin: Int? { Self.parsePositiveInt(salaryText) }
    /// The parsed desired-result-count goal, or `nil` when empty/non-numeric.
    var desiredResultCount: Int? { Self.parsePositiveInt(desiredResultText) }
    /// The effective minimum score, or `nil` when the slider is at 0 (no filter).
    var effectiveMinimumScore: Int? { minimumScore >= 1 ? Int(minimumScore) : nil }

    /// Location options: the static list merged with the user's saved locations (U-B).
    var locationOptions: [String] { suggestions.locationSuggestions(saved: savedLocations) }
    /// Salary preset options: built-in brackets merged with saved floors (U-C).
    var salaryPresetOptions: [Int] { SuggestionProvider.salaryPresets(saved: savedSalaries) }

    /// Saves the currently-typed location into the persisted library (U-B).
    func saveCurrentLocation() {
        let value = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !savedLocations.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame })
        else { return }
        savedLocations.append(value)
        locationStore?.save(savedLocations)
    }

    /// Removes a saved location from the library (U-B).
    func removeSavedLocation(_ value: String) {
        savedLocations.removeAll { $0.caseInsensitiveCompare(value) == .orderedSame }
        locationStore?.save(savedLocations)
    }

    /// Saves the currently-typed salary into the persisted library (U-C).
    func saveCurrentSalary() {
        guard let value = effectiveSalaryMin, !savedSalaries.contains(value) else { return }
        savedSalaries.append(value)
        salaryPresetStore?.save(savedSalaries)
    }

    /// Removes a saved salary preset from the library (U-C).
    func removeSavedSalary(_ value: Int) {
        savedSalaries.removeAll { $0 == value }
        salaryPresetStore?.save(savedSalaries)
    }

    /// Parses a positive integer from free text (digits + separators), else `nil`.
    private static func parsePositiveInt(_ text: String) -> Int? {
        let digits = text.filter(\.isNumber)
        guard let value = Int(digits), value > 0 else { return nil }
        return value
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

    /// The providers a search will actually run — selected **and** configured (Milestone H).
    var activeProviderIDs: Set<String> { selectedProviderIDs.intersection(configuredProviderIDs) }

    /// A banner shown when search can't run for a provider reason (no key configured, or none
    /// of the configured providers is selected). Distinct from `errorMessage` (run failures).
    var unavailableMessage: String? {
        guard activeProviderIDs.isEmpty else { return nil }
        return configuredProviderIDs.isEmpty
            ? "Search is unavailable — add a job-source API key in Settings → Sources."
            : "No search source selected — pick at least one configured provider below."
    }

    var canSearch: Bool {
        !activeProviderIDs.isEmpty && hasProfile && !effectiveTitles.isEmpty && !isSearching
    }

    // MARK: Provider selection (Milestone H)

    func isProviderSelected(_ id: String) -> Bool { selectedProviderIDs.contains(id) }
    func isProviderConfigured(_ id: String) -> Bool { configuredProviderIDs.contains(id) }

    /// Adds/removes a provider from the selection (drives the selector toggles).
    func setProvider(_ id: String, selected: Bool) {
        if selected { selectedProviderIDs.insert(id) } else { selectedProviderIDs.remove(id) }
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
            linkErrorMessage = Self.blockedPostingMessage(for: url)
        } catch {
            linkErrorMessage = Self.message(for: error)
        }
    }

    /// Job boards that serve an anti-bot / login wall (a Cloudflare "security check", 403, or
    /// JS challenge) to a plain fetch, so their posting URLs can never be read automatically.
    private static let botWalledBoards: [(host: String, name: String)] = [
        ("indeed.com", "Indeed"),
        ("linkedin.com", "LinkedIn"),
        ("glassdoor.com", "Glassdoor"),
        ("ziprecruiter.com", "ZipRecruiter"),
    ]

    /// A clear, board-aware message when a posting URL can't be fetched, pointing at the two
    /// paths that **do** work: paste the text, or search via an aggregator (JSearch) that
    /// licenses many of these boards.
    private static func blockedPostingMessage(for url: URL) -> String {
        let host = (url.host ?? "").lowercased()
        let board = botWalledBoards.first { host == $0.host || host.hasSuffix("." + $0.host) }?.name
        let lead = board.map {
            "\($0) blocks automated access to its job postings (an anti-bot / login wall), so this link can't be read automatically."
        } ?? "Couldn't read that posting — the page may need a login or block automated access."
        return lead + " Two ways to bring it in: paste the job description below and tap “Generate from pasted "
            + "text”, or run a New Search with JSearch enabled (Settings → Sources) — the JSearch aggregator "
            + "includes many of these boards' postings, with full descriptions."
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
        guard !activeProviderIDs.isEmpty else {
            errorMessage = unavailableMessage
            return
        }
        guard hasProfile else {
            errorMessage = "Build your profile on the Portfolio tab first."
            return
        }
        guard canSearch else { return }
        await performSearch(buildRequest(), isRerun: false)
    }

    /// Assembles the current form fields into a `JobSearchRequest`.
    func buildRequest() -> JobSearchRequest {
        JobSearchRequest(
            titles: effectiveTitles,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location,
            salaryMin: effectiveSalaryMin.map(Double.init),
            positionType: positionType,
            desiredResultCount: desiredResultCount,
            minimumScore: effectiveMinimumScore,
            sources: selectedProviderIDs.isEmpty ? nil : selectedProviderIDs.sorted()
        )
    }

    /// Runs `request` through the search→rank pipeline, pushes the results, and surfaces
    /// the soft notes. On a re-run (Milestone R) it also reports how many results are new
    /// since the last search (deduped against the saved-jobs store).
    private func performSearch(_ request: JobSearchRequest, isRerun: Bool) async {
        guard let profile else { return }
        isSearching = true
        errorMessage = nil
        warningMessage = nil
        defer { isSearching = false }

        let priorIDs: Set<String> = isRerun ? await savedJobIDs() : []
        do {
            let output = try await searchAndRank(request: request, profile: profile)
            results = output.rankedJobs
            var notes = [Self.note(for: output, minimumScore: request.minimumScore)].compactMap { $0 }
            if isRerun, !results.isEmpty {
                let newCount = results.filter { !priorIDs.contains($0.id) }.count
                notes.append("\(newCount) new since your last search.")
            }
            warningMessage = notes.isEmpty ? nil : notes.joined(separator: " ")
            await persistResults()
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    /// The ids of already-saved (previously-seen) ranked jobs, for the re-run "new" note.
    private func savedJobIDs() async -> Set<String> {
        guard let loadSavedJobs, let jobs = try? await loadSavedJobs() else { return [] }
        return Set(jobs.map(\.id))
    }

    /// Builds the combined soft-note line from a search outcome: failed titles (N-A),
    /// a result-count shortfall (U-D), and a none-met-minimum outcome (U-E). Each is a
    /// distinct, clear message; `nil` when there's nothing to report.
    static func note(for output: SearchAndRankUseCase.Output, minimumScore: Int?) -> String? {
        var notes = [String]()
        if !output.failedTitles.isEmpty {
            notes.append("Couldn't search: \(output.failedTitles.joined(separator: ", ")).")
        }
        if let shortfall = output.resultShortfall {
            notes.append("Found \(shortfall.found) of a desired \(shortfall.desired) — that's all that's available.")
        }
        if output.noneMetMinimum {
            notes.append("No results met your minimum rank of \(minimumScore ?? 0). Lower it to see more.")
        }
        return notes.isEmpty ? nil : notes.joined(separator: " ")
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
