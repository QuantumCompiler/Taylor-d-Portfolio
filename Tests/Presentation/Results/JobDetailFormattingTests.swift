//
//  JobDetailFormattingTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results — HTML stripping + salary formatting.
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("HTMLStripper")
struct HTMLStripperTests {

    @Test func stripsTagsAndKeepsText() {
        let html = "<p>Build <b>native</b> apps.</p>"
        #expect(HTMLStripper.plainText(html) == "Build native apps.")
    }

    @Test func turnsBreaksAndBlocksIntoNewlines() {
        let out = HTMLStripper.plainText("Line one<br>Line two<br/>Line three")
        #expect(out == "Line one\nLine two\nLine three")
    }

    @Test func decodesCommonEntities() {
        #expect(HTMLStripper.plainText("R&amp;D &lt;tags&gt; &quot;quoted&quot; it&#39;s") == "R&D <tags> \"quoted\" it's")
    }

    @Test func collapsesBlankLinesAndTrims() {
        let out = HTMLStripper.plainText("<div>A</div><div></div><div></div><div>B</div>")
        #expect(out == "A\n\nB")
    }

    @Test func plainTextPassesThroughUnchanged() {
        #expect(HTMLStripper.plainText("Just plain text.") == "Just plain text.")
    }
}

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
