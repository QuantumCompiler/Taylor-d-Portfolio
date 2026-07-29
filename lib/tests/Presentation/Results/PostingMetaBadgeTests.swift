//
//  PostingMetaBadgeTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results — pure badge derivation from a listing's richer detail.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("PostingMetaBadge")
struct PostingMetaBadgeTests {

    private func listing(
        positionTypes: [PositionType] = [],
        postedDate: Date? = nil,
        category: String? = nil,
        details: PostingDetails? = nil
    ) -> JobListing {
        JobListing(id: "a", title: "iOS", company: "Acme", location: "Remote", description: "d",
                   positionTypes: positionTypes, postedDate: postedDate, category: category, details: details)
    }

    @Test func unenrichedListingYieldsNoBadges() {
        #expect(PostingMetaBadge.badges(for: listing()).isEmpty)
    }

    @Test func badgesCoverWorkTypeEmploymentPostedAndCategoryInOrder() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let posted = now.addingTimeInterval(-2 * 86_400)   // 2 days earlier
        let job = listing(
            positionTypes: [.permanent, .fullTime],
            postedDate: posted,
            category: "IT Jobs",
            details: PostingDetails(workTypeRaw: "remote")
        )
        let badges = PostingMetaBadge.badges(for: job, calendar: .current, now: now)

        #expect(badges.map(\.kind) == [.workType, .employment, .employment, .posted, .category])
        #expect(badges[0].text == "Remote")          // work type first
        #expect(badges[1].text == "Permanent")
        #expect(badges[2].text == "Full-time")
        #expect(badges[3].text == "Posted 2 days ago")
        #expect(badges[4].text == "IT Jobs")
    }

    @Test func blankCategoryIsSkipped() {
        let badges = PostingMetaBadge.badges(for: listing(category: "   "))
        #expect(badges.isEmpty)
    }

    @Test func postedTextIsRelativeAndHandlesEdges() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        #expect(PostingMetaBadge.postedText(now, now: now) == "Posted today")
        #expect(PostingMetaBadge.postedText(now.addingTimeInterval(-86_400), now: now) == "Posted 1 day ago")
        #expect(PostingMetaBadge.postedText(now.addingTimeInterval(-5 * 86_400), now: now) == "Posted 5 days ago")
        // A future date (clock skew) degrades gracefully rather than showing a negative count.
        #expect(PostingMetaBadge.postedText(now.addingTimeInterval(86_400), now: now) == "Posted recently")
    }
}
