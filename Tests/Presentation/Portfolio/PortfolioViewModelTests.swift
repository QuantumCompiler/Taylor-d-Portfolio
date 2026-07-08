//
//  PortfolioViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Portfolio
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@MainActor
@Suite("PortfolioViewModel")
struct PortfolioViewModelTests {

    private func makeVM(
        buildThrows: Bool = false,
        importText: String = "IMPORTED",
        importThrows: Bool = false
    ) -> PortfolioViewModel {
        PortfolioViewModel(
            buildProfile: BuildProfileUseCase(provider: PresentationStubProvider(shouldThrow: buildThrows)),
            importPortfolio: ImportPortfolioUseCase(extractor: PresentationStubExtractor(text: importText, shouldThrow: importThrows))
        )
    }

    @Test func buildSetsProfileOnSuccess() async {
        let vm = makeVM()
        vm.portfolioText = "my portfolio"
        await vm.build()
        #expect(vm.profile?.seniority == "BUILT")
        #expect(vm.errorMessage == nil)
        #expect(vm.isBuilding == false)
    }

    @Test func buildSetsErrorOnFailure() async {
        let vm = makeVM(buildThrows: true)
        vm.portfolioText = "text"
        await vm.build()
        #expect(vm.profile == nil)
        #expect(vm.errorMessage != nil)
    }

    @Test func canBuildRequiresNonEmptyText() {
        let vm = makeVM()
        #expect(vm.canBuild == false)
        vm.portfolioText = "   "
        #expect(vm.canBuild == false)
        vm.portfolioText = "real content"
        #expect(vm.canBuild == true)
    }

    @Test func importDocumentFillsPortfolioText() async {
        let vm = makeVM(importText: "EXTRACTED RESUME TEXT")
        await vm.importDocument(from: URL(fileURLWithPath: "/tmp/portfolio.pdf"))
        #expect(vm.portfolioText == "EXTRACTED RESUME TEXT")
        #expect(vm.errorMessage == nil)
        #expect(vm.isImporting == false)
    }

    @Test func importDocumentFailureSetsError() async {
        let vm = makeVM(importThrows: true)
        await vm.importDocument(from: URL(fileURLWithPath: "/tmp/broken.pdf"))
        #expect(vm.portfolioText.isEmpty)
        #expect(vm.errorMessage != nil)
        #expect(vm.isImporting == false)
    }
}
