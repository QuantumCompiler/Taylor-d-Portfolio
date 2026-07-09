//
//  JobDetailFormatting.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · View — pure display formatters for the detail view.
//

import Foundation

/// Formats an optional ``SalaryRange`` into a display string, or `nil` when there's
/// nothing to show. Pure, so it's unit-tested directly.
nonisolated enum SalaryFormatter {
    static func text(_ range: SalaryRange) -> String? {
        let prefix = range.currency.map { "\($0) " } ?? "$"
        func money(_ value: Double) -> String { prefix + Int(value).formatted() }

        switch (range.min, range.max) {
        case let (min?, max?): return min == max ? money(min) : "\(money(min)) – \(money(max))"
        case let (min?, nil):  return "\(money(min))+"
        case let (nil, max?):  return "Up to \(money(max))"
        case (nil, nil):       return nil
        }
    }
}
