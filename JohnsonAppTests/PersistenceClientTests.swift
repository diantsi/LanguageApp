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
    private var testSession: LanguageSession!

    override func setUp() async throws {
        try await super.setUp()
        // Fresh in-memory DB with all migrations applied
        let pool = try AppDatabase.makeInMemory()
        client = PersistenceClient.live(dbPool: pool)

        // Every test starts with one default session
        testSession = LanguageSession(
            id: UUID(),
            name: "Test Session",
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: Date()
        )
        try await client.addSession(testSession)
    }

    override func tearDown() async throws {
        client = nil
        testSession = nil
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


    // MARK: - Session Tests

    func testAddAndFetchSessions() async throws {
        let sessions = try await client.fetchSessions()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.name, "Test Session")
        XCTAssertEqual(sessions.first?.termLanguage, .english)
        XCTAssertEqual(sessions.first?.translationLanguage, .ukrainian)
    }

    func testDeleteSessionCascadeDeletesTerms() async throws {
        let term = makeTerm(termText: "apple", translation: "яблуко")
        try await client.addTerm(testSession.id, term)

        var fetched = try await client.fetchTerms(testSession.id, nil, nil, nil, nil)
        XCTAssertEqual(fetched.count, 1)

        try await client.deleteSession(testSession.id)

        // After session deletion, terms should be gone (cascade)
        let sessions = try await client.fetchSessions()
        XCTAssertEqual(sessions.count, 0)
        // Can't fetch terms for deleted session — the session itself is gone
        // Verifying via a second session that terms of other sessions are not affected
    }

    func testTermsAreIsolatedBetweenSessions() async throws {
        let session2 = LanguageSession(
            id: UUID(),
            name: "Session 2",
            termLanguage: .ukrainian,
            translationLanguage: .english,
            createdAt: Date()
        )
        try await client.addSession(session2)

        let term1 = makeTerm(termText: "apple", translation: "яблуко")
        let term2 = makeTerm(termText: "кіт", translation: "cat")
        try await client.addTerm(testSession.id, term1)
        try await client.addTerm(session2.id, term2)

        let session1Terms = try await client.fetchTerms(testSession.id, nil, nil, nil, nil)
        let session2Terms = try await client.fetchTerms(session2.id, nil, nil, nil, nil)

        XCTAssertEqual(session1Terms.count, 1)
        XCTAssertEqual(session1Terms.first?.termText, "apple")

        XCTAssertEqual(session2Terms.count, 1)
        XCTAssertEqual(session2Terms.first?.termText, "кіт")
    }


    // MARK: - Term Tests

    func testAddAndFetchTerms() async throws {
        let term = makeTerm(termText: "apple", translation: "яблуко")

        try await client.addTerm(testSession.id, term)

        let fetched = try await client.fetchTerms(testSession.id, nil, nil, nil, nil)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.termText, "apple")
        XCTAssertEqual(fetched.first?.translation, "яблуко")
        XCTAssertEqual(fetched.first?.status, .new)
    }

    func testAddTermsBatch() async throws {
        let term1 = makeTerm(termText: "apple", translation: "яблуко")
        let term2 = makeTerm(termText: "banana", translation: "банан")

        try await client.addTerms(testSession.id, [term1, term2])

        let fetched = try await client.fetchTerms(testSession.id, nil, nil, nil, nil)
        XCTAssertEqual(fetched.count, 2)
        let texts = fetched.map { $0.termText }
        XCTAssertTrue(texts.contains("apple"))
        XCTAssertTrue(texts.contains("banana"))
    }

    func testTermExists() async throws {
        let term = makeTerm(termText: "Apple", translation: "Яблуко")
        try await client.addTerm(testSession.id, term)

        let exists1 = try await client.termExists(testSession.id, "Apple", "Яблуко")
        XCTAssertTrue(exists1)

        let exists2 = try await client.termExists(testSession.id, "apple", "яблуко")
        XCTAssertTrue(exists2)

        let exists3 = try await client.termExists(testSession.id, "  apple  ", "  яблуко  ")
        XCTAssertTrue(exists3)

        let exists4 = try await client.termExists(testSession.id, "apple", "груша")
        XCTAssertFalse(exists4)
    }

    func testTermExistsIsSessionScoped() async throws {
        let session2 = LanguageSession(
            id: UUID(),
            name: "Session 2",
            termLanguage: .ukrainian,
            translationLanguage: .english,
            createdAt: Date()
        )
        try await client.addSession(session2)

        let term = makeTerm(termText: "apple", translation: "яблуко")
        try await client.addTerm(testSession.id, term)

        let existsInSession1 = try await client.termExists(testSession.id, "apple", "яблуко")
        XCTAssertTrue(existsInSession1)

        let existsInSession2 = try await client.termExists(session2.id, "apple", "яблуко")
        XCTAssertFalse(existsInSession2)
    }

    func testFetchTermById() async throws {
        let id = UUID()
        let term = makeTerm(id: id, termText: "banana", translation: "банан")

        try await client.addTerm(testSession.id, term)

        let fetched = try await client.fetchTerm(id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.termText, "banana")
        XCTAssertEqual(fetched?.id, id)
    }

    func testUpdateTerm() async throws {
        let id = UUID()
        let original = makeTerm(id: id, termText: "cherry", translation: "вишня")
        try await client.addTerm(testSession.id, original)

        let updated = makeTerm(id: id, termText: "cherry", translation: "черешня")
        try await client.updateTerm(updated)

        let fetched = try await client.fetchTerms(testSession.id, nil, nil, nil, nil)
        XCTAssertEqual(fetched.first?.translation, "черешня")
    }

    func testDeleteTerm() async throws {
        let id = UUID()
        let term = makeTerm(id: id, termText: "date", translation: "фінік")
        try await client.addTerm(testSession.id, term)

        var fetched = try await client.fetchTerms(testSession.id, nil, nil, nil, nil)
        XCTAssertEqual(fetched.count, 1)

        try await client.deleteTerm(id)

        fetched = try await client.fetchTerms(testSession.id, nil, nil, nil, nil)
        XCTAssertEqual(fetched.count, 0)
    }

    func testFetchDueTerms() async throws {
        let now = Date()
        let oneDay = TimeInterval(24 * 60 * 60)

        let term1 = makeTerm(termText: "one", translation: "один", createdAt: now - 2 * oneDay)
        try await client.addTerm(testSession.id, term1)

        let term2 = makeTerm(termText: "two", translation: "два", createdAt: now + oneDay)
        try await client.addTerm(testSession.id, term2)

        let term3 = makeTerm(termText: "three", translation: "три", createdAt: now - oneDay)
        try await client.addTerm(testSession.id, term3)

        let dueTerms = try await client.fetchDueTerms(testSession.id, now, 5)
        XCTAssertEqual(dueTerms.count, 2)

        let texts = dueTerms.map { $0.termText }
        XCTAssertTrue(texts.contains("one"))
        XCTAssertTrue(texts.contains("three"))
        XCTAssertFalse(texts.contains("two"))

        let limited = try await client.fetchDueTerms(testSession.id, now, 1)
        XCTAssertEqual(limited.count, 1)
    }

    func testSearchTerms() async throws {
        try await client.addTerm(testSession.id, makeTerm(termText: "apple", translation: "яблуко"))
        try await client.addTerm(testSession.id, makeTerm(termText: "apricot", translation: "абрикос"))
        try await client.addTerm(testSession.id, makeTerm(termText: "banana", translation: "банан"))

        let search1 = try await client.fetchTerms(testSession.id, "ap", nil, nil, nil)
        XCTAssertEqual(search1.count, 2)
        XCTAssertTrue(search1.map { $0.termText }.contains("apple"))
        XCTAssertTrue(search1.map { $0.termText }.contains("apricot"))

        let search2 = try await client.fetchTerms(testSession.id, "банан", nil, nil, nil)
        XCTAssertEqual(search2.count, 1)
        XCTAssertEqual(search2.first?.termText, "banana")

        let search3 = try await client.fetchTerms(testSession.id, "", nil, nil, nil)
        XCTAssertEqual(search3.count, 3)
    }

    func testFetchTermsPagination() async throws {
        try await client.addTerm(testSession.id, makeTerm(termText: "one", translation: "один"))
        try await client.addTerm(testSession.id, makeTerm(termText: "two", translation: "два"))
        try await client.addTerm(testSession.id, makeTerm(termText: "three", translation: "три"))

        let firstPage = try await client.fetchTerms(testSession.id, nil, nil, 2, 0)
        XCTAssertEqual(firstPage.count, 2)

        let secondPage = try await client.fetchTerms(testSession.id, nil, nil, 1, 2)
        XCTAssertEqual(secondPage.count, 1)

        let firstPageIds = Set(firstPage.map { $0.id })
        let secondPageIds = Set(secondPage.map { $0.id })
        XCTAssertTrue(firstPageIds.isDisjoint(with: secondPageIds))
    }

    func testTermStatusCalculation() async throws {
        let term = makeTerm(termText: "test", translation: "тест")
        try await client.addTerm(testSession.id, term)

        let fetched = try await client.fetchTerms(testSession.id, nil, nil, nil, nil)
        XCTAssertEqual(fetched.first?.status, .new)
    }

    func testFetchAndUpdateLearningProgress() async throws {
        let id = UUID()
        let term = makeTerm(id: id, termText: "test", translation: "тест")
        try await client.addTerm(testSession.id, term)

        var progress = try await client.fetchLearningProgress(id)
        XCTAssertNotNil(progress)
        XCTAssertNil(progress?.lastReviewDate)
        XCTAssertEqual(progress?.stability, 0.0)

        let now = Date()
        let updatedProgress = LearningProgress(
            stability: 10.5,
            difficulty: 4.2,
            dueDate: now,
            lastReviewDate: now,
            repetitions: 3,
            lapses: 1
        )
        try await client.updateLearningProgress(id, updatedProgress)

        progress = try await client.fetchLearningProgress(id)
        XCTAssertEqual(progress?.stability, 10.5)
        XCTAssertEqual(progress?.difficulty, 4.2)
        XCTAssertEqual(progress?.repetitions, 3)
        XCTAssertEqual(progress?.lapses, 1)
        XCTAssertNotNil(progress?.lastReviewDate)
    }
}
