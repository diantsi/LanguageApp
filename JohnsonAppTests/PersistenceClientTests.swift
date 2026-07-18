//
//  PersistenceClientTests.swift
//  JohnsonApp
//

import XCTest
import SwiftData
@testable import JohnsonApp

@MainActor
final class PersistenceClientTests: XCTestCase {
    private var testContainer: ModelContainer!
    private var client: PersistenceClient!

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([
            Term.self,
            LearningProgress.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        testContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

        client = PersistenceClient.live(modelContainer: testContainer)
    }

    override func tearDown() async throws {
        testContainer = nil
        client = nil
        try await super.tearDown()
    }

    func testAddAndFetchTerms() async throws {
        let term = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )

        try await client.addTerm(term)

        let fetchedTerms = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetchedTerms.count, 1)
        XCTAssertEqual(fetchedTerms.first?.termText, "apple")
        XCTAssertEqual(fetchedTerms.first?.translation, "яблуко")
        XCTAssertNotNil(fetchedTerms.first?.learningProgress)
        XCTAssertEqual(fetchedTerms.first?.learningProgress?.stability, 0.0)
    }

    func testAddTermsBatch() async throws {
        let term1 = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        let term2 = Term(
            termText: "banana",
            translation: "банан",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )

        try await client.addTerms([term1, term2])

        let fetchedTerms = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetchedTerms.count, 2)
        let texts = fetchedTerms.map { $0.termText }
        XCTAssertTrue(texts.contains("apple"))
        XCTAssertTrue(texts.contains("banana"))
    }

    func testTermExists() async throws {
        let term = Term(
            termText: "Apple",
            translation: "Яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        try await client.addTerm(term)

        let exists1 = try await client.termExists("Apple", "Яблуко")
        XCTAssertTrue(exists1)

        let exists2 = try await client.termExists("apple", "яблуко")
        XCTAssertTrue(exists2)

        let exists3 = try await client.termExists("  apple  ", "  яблуко  ")
        XCTAssertTrue(exists3)

        let exists4 = try await client.termExists("apple", "груша")
        XCTAssertFalse(exists4)
    }

    func testFetchTermById() async throws {
        let id = UUID()
        let term = Term(
            id: id,
            termText: "banana",
            translation: "банан",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )

        try await client.addTerm(term)

        let fetchedTerm = try await client.fetchTerm(id)
        XCTAssertNotNil(fetchedTerm)
        XCTAssertEqual(fetchedTerm?.termText, "banana")
    }

    func testUpdateTerm() async throws {
        let term = Term(
            termText: "cherry",
            translation: "вишня",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )

        try await client.addTerm(term)

        term.translation = "черешня"
        try await client.updateTerm(term)

        let fetchedTerms = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetchedTerms.first?.translation, "черешня")
    }

    func testDeleteTerm() async throws {
        let id = UUID()
        let term = Term(
            id: id,
            termText: "date",
            translation: "фінік",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )

        try await client.addTerm(term)

        var fetchedTerms = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetchedTerms.count, 1)

        try await client.deleteTerm(id)

        fetchedTerms = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetchedTerms.count, 0)
    }

    func testFetchDueTerms() async throws {
        let now = Date()
        let oneDay = TimeInterval(24 * 60 * 60)

        let term1 = Term(
            termText: "one",
            translation: "один",
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: now - 2 * oneDay
        )
        term1.learningProgress?.dueDate = now - oneDay
        try await client.addTerm(term1)

        let term2 = Term(
            termText: "two",
            translation: "два",
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: now
        )
        term2.learningProgress?.dueDate = now + oneDay
        try await client.addTerm(term2)

        let term3 = Term(
            termText: "three",
            translation: "три",
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: now - oneDay
        )
        term3.learningProgress?.dueDate = now
        try await client.addTerm(term3)

        let dueTerms = try await client.fetchDueTerms(now, 5)
        XCTAssertEqual(dueTerms.count, 2)

        let texts = dueTerms.map { $0.termText }
        XCTAssertTrue(texts.contains("one"))
        XCTAssertTrue(texts.contains("three"))
        XCTAssertFalse(texts.contains("two"))

        let limitedDueTerms = try await client.fetchDueTerms(now, 1)
        XCTAssertEqual(limitedDueTerms.count, 1)
    }

    func testSearchTerms() async throws {
        let term1 = Term(termText: "apple", translation: "яблуко", termLanguage: .english, translationLanguage: .ukrainian)
        let term2 = Term(termText: "apricot", translation: "абрикос", termLanguage: .english, translationLanguage: .ukrainian)
        let term3 = Term(termText: "banana", translation: "банан", termLanguage: .english, translationLanguage: .ukrainian)

        try await client.addTerm(term1)
        try await client.addTerm(term2)
        try await client.addTerm(term3)

        let search1 = try await client.fetchTerms("ap", nil, nil, nil)
        XCTAssertEqual(search1.count, 2)
        let texts1 = search1.map { $0.termText }
        XCTAssertTrue(texts1.contains("apple"))
        XCTAssertTrue(texts1.contains("apricot"))

        let search2 = try await client.fetchTerms("банан", nil, nil, nil)
        XCTAssertEqual(search2.count, 1)
        XCTAssertEqual(search2.first?.termText, "banana")

        let search3 = try await client.fetchTerms("", nil, nil, nil)
        XCTAssertEqual(search3.count, 3)
    }

    func testFetchTermsPagination() async throws {
        let term1 = Term(termText: "one", translation: "один", termLanguage: .english, translationLanguage: .ukrainian)
        let term2 = Term(termText: "two", translation: "два", termLanguage: .english, translationLanguage: .ukrainian)
        let term3 = Term(termText: "three", translation: "три", termLanguage: .english, translationLanguage: .ukrainian)

        try await client.addTerm(term1)
        try await client.addTerm(term2)
        try await client.addTerm(term3)

        let firstPage = try await client.fetchTerms(nil, nil, 2, 0)
        XCTAssertEqual(firstPage.count, 2)

        let secondPage = try await client.fetchTerms(nil, nil, 1, 2)
        XCTAssertEqual(secondPage.count, 1)

        let firstPageIds = Set(firstPage.map { $0.id })
        let secondPageIds = Set(secondPage.map { $0.id })
        XCTAssertTrue(firstPageIds.isDisjoint(with: secondPageIds))
    }

    func testTermStatusCalculation() {
        let term = Term(termText: "test", translation: "тест", termLanguage: .english, translationLanguage: .ukrainian)

        XCTAssertEqual(term.status, .new)

        term.learningProgress?.lastReviewDate = Date()
        term.learningProgress?.stability = 150.0
        XCTAssertEqual(term.status, .learning)

        term.learningProgress?.stability = 366.0
        XCTAssertEqual(term.status, .mastered)
    }
}
