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

    /// The user's persisted library of common role titles, shown as toggle tiles.
    private(set) var commonRoleTitles: [String] = []
    /// Which common role titles are toggled on (searched alongside the chips).
    private(set) var selectedCommonTitles: [String] = []

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

    init(
        searchAndRank: SearchAndRankUseCase,
        suggestions: SuggestionProvider = SuggestionProvider(),
        roleTitleStore: RoleTitleStore,
        adzunaConfigured: Bool = true
    ) {
        self.searchAndRank = searchAndRank
        self.suggestions = suggestions
        self.roleTitleStore = roleTitleStore
        self.adzunaConfigured = adzunaConfigured
        self.commonRoleTitles = roleTitleStore.load()
    }

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
