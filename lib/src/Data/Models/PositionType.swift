//
//  PositionType.swift
//  Taylor'd Portfolio
//
//  Data · Models — an optional employment-type filter for search.
//

import Foundation

/// The kind of employment a search is limited to. Optional everywhere — leaving it unset
/// keeps today's unfiltered behaviour. The raw values are the Adzuna contract-parameter
/// names, but the enum itself stays source-agnostic (the mapping lives in `AdzunaJobSource`).
nonisolated enum PositionType: String, CaseIterable, Codable, Sendable, Identifiable {
    case fullTime = "full_time"
    case partTime = "part_time"
    case contract
    case permanent

    var id: String { rawValue }

    /// A human-readable label for the picker.
    var label: String {
        switch self {
        case .fullTime: return "Full-time"
        case .partTime: return "Part-time"
        case .contract: return "Contract"
        case .permanent: return "Permanent"
        }
    }
}
