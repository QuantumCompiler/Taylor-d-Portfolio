//
//  JobDetailFooterTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results — the pure job-detail footer decision (v0.5.0 Milestone A).
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("JobDetailFooter")
struct JobDetailFooterTests {
    // Tracker context (canGenerate == true).

    @Test func trackerWithoutMaterialsShowsGenerateOnly() {
        #expect(
            JobDetailFooter.resolve(canGenerate: true, hasGeneratedMaterials: false, canSaveToTracker: false)
            == .generate
        )
    }

    @Test func trackerWithMaterialsShowsViewAndRegenerate() {
        #expect(
            JobDetailFooter.resolve(canGenerate: true, hasGeneratedMaterials: true, canSaveToTracker: false)
            == .viewAndRegenerate
        )
    }

    // Results context (canGenerate == false) never offers Generate/View, regardless of materials.

    @Test func resultsWithSaveActionShowsSaveToTracker() {
        #expect(
            JobDetailFooter.resolve(canGenerate: false, hasGeneratedMaterials: false, canSaveToTracker: true)
            == .saveToTracker
        )
        // Even if a kit somehow exists, the Results footer stays Save-only (no generation there).
        #expect(
            JobDetailFooter.resolve(canGenerate: false, hasGeneratedMaterials: true, canSaveToTracker: true)
            == .saveToTracker
        )
    }

    @Test func resultsWithoutSaveActionShowsNothing() {
        #expect(
            JobDetailFooter.resolve(canGenerate: false, hasGeneratedMaterials: false, canSaveToTracker: false)
            == JobDetailFooter.none
        )
    }
}
