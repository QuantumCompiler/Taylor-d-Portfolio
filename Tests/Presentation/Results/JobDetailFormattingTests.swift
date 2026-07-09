//
//  JobDetailFormattingTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results — salary formatting.
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("SalaryFormatter")
struct SalaryFormatterTests {

    @Test func formatsRange() {
        #expect(SalaryFormatter.text(SalaryRange(min: 120_000, max: 160_000)) == "$120,000 – $160,000")
    }

    @Test func formatsMinOnlyAndMaxOnly() {
        #expect(SalaryFormatter.text(SalaryRange(min: 120_000)) == "$120,000+")
        #expect(SalaryFormatter.text(SalaryRange(max: 160_000)) == "Up to $160,000")
    }

    @Test func collapsesEqualMinMax() {
        #expect(SalaryFormatter.text(SalaryRange(min: 100_000, max: 100_000)) == "$100,000")
    }

    @Test func usesCurrencyWhenPresent() {
        #expect(SalaryFormatter.text(SalaryRange(min: 90_000, currency: "GBP")) == "GBP 90,000+")
    }

    @Test func emptyRangeIsNil() {
        #expect(SalaryFormatter.text(SalaryRange()) == nil)
    }
}
