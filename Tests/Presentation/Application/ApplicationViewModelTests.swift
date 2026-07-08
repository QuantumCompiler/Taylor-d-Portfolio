//
//  ApplicationViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Application
//

import Testing
@testable import Taylor_d_Portfolio

@MainActor
@Suite("ApplicationViewModel")
struct ApplicationViewModelTests {

    private let job = JobListing(id: "a", title: "t", company: "c", location: "l", description: "d")
    private var profile: CandidateProfile {
        CandidateProfile(seniority: "S", yearsExperience: 1, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }

    @Test func generateSetsKitOnSuccess() async {
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(kitResume: "RESUME"))
        )
        await vm.generate(for: job, profile: profile)
        #expect(vm.kit?.resumeMarkdown == "RESUME")
        #expect(vm.errorMessage == nil)
        #expect(vm.isGenerating == false)
    }

    @Test func generateSetsErrorOnFailure() async {
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: PresentationStubProvider(shouldThrow: true))
        )
        await vm.generate(for: job, profile: profile)
        #expect(vm.kit == nil)
        #expect(vm.errorMessage != nil)
        #expect(vm.isGenerating == false)
    }
}
