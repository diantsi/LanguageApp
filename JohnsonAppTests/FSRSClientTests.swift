//
//  FSRSClientTests.swift
//  JohnsonApp
//

import XCTest
import ComposableArchitecture
@testable import JohnsonApp

final class FSRSClientTests: XCTestCase {

    func testFirstReviewNewCard() {
        let client = FSRSClient.liveValue
        let now = Date()
        let calendar = Calendar.current
        let initialProgress = LearningProgress(dueDate: now)

        // Rating: Again
        let againResult = client.schedule(initialProgress, .again, now)
        XCTAssertEqual(againResult.stability, 0.212, accuracy: 0.001)
        XCTAssertGreaterThan(againResult.difficulty, 5.0)
        XCTAssertEqual(againResult.repetitions, 1)
        XCTAssertEqual(againResult.lapses, 1)
        XCTAssertEqual(againResult.status, .learning)
        XCTAssertEqual(againResult.dueDate, calendar.startOfDay(for: now))

        // Rating: Hard
        let hardResult = client.schedule(initialProgress, .hard, now)
        XCTAssertEqual(hardResult.stability, 1.2931, accuracy: 0.001)
        XCTAssertEqual(hardResult.repetitions, 1)
        XCTAssertEqual(hardResult.lapses, 0)
        XCTAssertEqual(hardResult.status, .learning)

        // Rating: Good
        let goodResult = client.schedule(initialProgress, .good, now)
        XCTAssertEqual(goodResult.stability, 2.3065, accuracy: 0.001)
        XCTAssertEqual(goodResult.repetitions, 1)
        XCTAssertEqual(goodResult.lapses, 0)
        XCTAssertEqual(goodResult.status, .learning)
        let expectedGoodDue = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: now))!
        XCTAssertEqual(goodResult.dueDate, expectedGoodDue)

        // Rating: Easy
        let easyResult = client.schedule(initialProgress, .easy, now)
        XCTAssertEqual(easyResult.stability, 8.2956, accuracy: 0.001)
        XCTAssertEqual(easyResult.repetitions, 1)
        XCTAssertEqual(easyResult.lapses, 0)
        XCTAssertEqual(easyResult.status, .learning)
        let expectedEasyDue = calendar.date(byAdding: .day, value: 8, to: calendar.startOfDay(for: now))!
        XCTAssertEqual(easyResult.dueDate, expectedEasyDue)
    }

    func testSubsequentReviewGood() {
        let client = FSRSClient.liveValue
        let now = Date()
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!

        let progress = LearningProgress(
            stability: 2.3065,
            difficulty: 6.4133,
            dueDate: threeDaysAgo,
            lastReviewDate: threeDaysAgo,
            repetitions: 1,
            lapses: 0
        )

        let nextProgress = client.schedule(progress, .good, now)

        XCTAssertGreaterThan(nextProgress.stability, progress.stability)
        XCTAssertEqual(nextProgress.repetitions, 2)
        XCTAssertEqual(nextProgress.lapses, 0)
        XCTAssertNotNil(nextProgress.lastReviewDate)
        XCTAssertGreaterThan(nextProgress.dueDate, now)
    }

    func testSameDayShortTermReview() {
        let client = FSRSClient.liveValue
        let now = Date()

        let progress = LearningProgress(
            stability: 2.0,
            difficulty: 5.0,
            dueDate: now,
            lastReviewDate: now,
            repetitions: 1,
            lapses: 0
        )

        // Same day review with Good rating
        let nextProgress = client.schedule(progress, .good, now)
        XCTAssertGreaterThanOrEqual(nextProgress.stability, progress.stability)
        XCTAssertEqual(nextProgress.repetitions, 2)
    }

    func testSubsequentReviewAgainLapse() {
        let client = FSRSClient.liveValue
        let now = Date()
        let calendar = Calendar.current
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: now)!

        let progress = LearningProgress(
            stability: 10.0,
            difficulty: 4.0,
            dueDate: tenDaysAgo,
            lastReviewDate: tenDaysAgo,
            repetitions: 3,
            lapses: 0
        )

        let nextProgress = client.schedule(progress, .again, now)

        XCTAssertLessThan(nextProgress.stability, progress.stability)
        XCTAssertEqual(nextProgress.repetitions, 4)
        XCTAssertEqual(nextProgress.lapses, 1)
    }

    func testMasteredStatusThreshold() {
        let now = Date()

        let highStabilityProgress = LearningProgress(
            stability: 370.0,
            difficulty: 2.0,
            dueDate: now,
            lastReviewDate: now,
            repetitions: 10,
            lapses: 0
        )

        XCTAssertEqual(highStabilityProgress.status, .mastered)
    }
}
