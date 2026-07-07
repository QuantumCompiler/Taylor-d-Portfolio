//
//  SalaryRange.swift
//  Taylor'd Portfolio
//
//  Data · Models — optional pay range on a job listing.
//

import Foundation

/// An optional pay range attached to a ``JobListing``. Every field is optional
/// because job sources rarely provide all of them.
nonisolated struct SalaryRange: Codable, Equatable, Sendable {
    var min: Double?
    var max: Double?
    var currency: String?

    init(min: Double? = nil, max: Double? = nil, currency: String? = nil) {
        self.min = min
        self.max = max
        self.currency = currency
    }
}
