//
//  PersistenceClientTests.swift
//  JohnsonApp
//

import XCTest
import GRDB
@testable import JohnsonApp

@MainActor
final class PersistenceClientTests: XCTestCase {
    private var client: PersistenceClient!

    override func setUp() async throws {
        try await super.setUp()
        // Кожен тест отримує чисту in-memory БД з накатаними міграціями
        let pool = try AppDatabase.makeInMemory()
        client = PersistenceClient.live(dbPool: pool)
    }

    override func tearDown() async throws {
        client = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeTerm(
        id: UUID = UUID(),
        termText: String,
        translation: String,
        hint: String? = nil,
        termLanguage: Language = .english,
        translationLanguage: Language = .ukrainian,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Term {
        Term(
            id: id,
            termText: termText,
            translation: translation,
            hint: hint,
            termLanguage: termLanguage,
            translationLanguage: translationLanguage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: .new
        )
    }

    // MARK: - Tests

    func testAddAndFetchTerms() async throws {
        let term = makeTerm(termText: "apple", translation: "яблуко")

        try await client.addTerm(term)

        let fetched = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.termText, "apple")
        XCTAssertEqual(fetched.first?.translation, "яблуко")
        XCTAssertEqual(fetched.first?.status, .new)
    }

    func testAddTermsBatch() async throws {
        let term1 = makeTerm(termText: "apple", translation: "яблуко")
        let term2 = makeTerm(termText: "banana", translation: "банан")

        try await client.addTerms([term1, term2])

        let fetched = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetched.count, 2)
        let texts = fetched.map { $0.termText }
        XCTAssertTrue(texts.contains("apple"))
        XCTAssertTrue(texts.contains("banana"))
    }

    func testTermExists() async throws {
        let term = makeTerm(termText: "Apple", translation: "Яблуко")
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
        let term = makeTerm(id: id, termText: "banana", translation: "банан")

        try await client.addTerm(term)

        let fetched = try await client.fetchTerm(id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.termText, "banana")
        XCTAssertEqual(fetched?.id, id)
    }

    func testUpdateTerm() async throws {
        let id = UUID()
        let original = makeTerm(id: id, termText: "cherry", translation: "вишня")
        try await client.addTerm(original)

        let updated = makeTerm(id: id, termText: "cherry", translation: "черешня")
        try await client.updateTerm(updated)

        let fetched = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetched.first?.translation, "черешня")
    }

    func testDeleteTerm() async throws {
        let id = UUID()
        let term = makeTerm(id: id, termText: "date", translation: "фінік")
        try await client.addTerm(term)

        var fetched = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetched.count, 1)

        try await client.deleteTerm(id)

        fetched = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetched.count, 0)
    }

    func testFetchDueTerms() async throws {
        let now = Date()
        let oneDay = TimeInterval(24 * 60 * 60)

        // overdue — dueDate is yesterday
        let term1 = makeTerm(termText: "one", translation: "один", createdAt: now - 2 * oneDay)
        try await client.addTerm(term1)

        // not yet due — dueDate is tomorrow
        let term2 = makeTerm(termText: "two", translation: "два", createdAt: now + oneDay)
        try await client.addTerm(term2)

        // due now — dueDate == now
        let term3 = makeTerm(termText: "three", translation: "три", createdAt: now - oneDay)
        try await client.addTerm(term3)

        let dueTerms = try await client.fetchDueTerms(now, 5)
        XCTAssertEqual(dueTerms.count, 2)

        let texts = dueTerms.map { $0.termText }
        XCTAssertTrue(texts.contains("one"))
        XCTAssertTrue(texts.contains("three"))
        XCTAssertFalse(texts.contains("two"))

        let limited = try await client.fetchDueTerms(now, 1)
        XCTAssertEqual(limited.count, 1)
    }

    func testSearchTerms() async throws {
        let term1 = makeTerm(termText: "apple", translation: "яблуко")
        let term2 = makeTerm(termText: "apricot", translation: "абрикос")
        let term3 = makeTerm(termText: "banana", translation: "банан")

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
        let term1 = makeTerm(termText: "one", translation: "один")
        let term2 = makeTerm(termText: "two", translation: "два")
        let term3 = makeTerm(termText: "three", translation: "три")

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

    func testTermStatusCalculation() async throws {
        let term = makeTerm(termText: "test", translation: "тест")
        try await client.addTerm(term)

        let fetched = try await client.fetchTerms(nil, nil, nil, nil)
        XCTAssertEqual(fetched.first?.status, .new)
    }
}
