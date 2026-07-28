//
//  AddTermsFeatureTests.swift
//  JohnsonApp
//

import ComposableArchitecture
import XCTest
@testable import JohnsonApp

@MainActor
final class AddTermsFeatureTests: XCTestCase {

    // MARK: - Input

    func testInputTextChangedClearsParsed() async throws {
        let store = TestStore(
            initialState: AddTermsFeature.State(isParsed: true)
        ) {
            AddTermsFeature()
        }

        await store.send(.inputTextChanged("new text")) {
            $0.inputText = "new text"
            $0.isParsed = false
        }
    }

    // MARK: - Parse

    func testParseButtonTappedParsesText() async throws {
        let parsed = ParsedTerm(termText: "apple", translation: "яблуко")
        let result = ImportResult(validTerms: [parsed], invalidLines: [])

        let store = TestStore(initialState: AddTermsFeature.State(inputText: "apple - яблуко")) {
            AddTermsFeature()
        } withDependencies: {
            $0.importClient.parse = { _ in result }
            $0.persistenceClient.termExists = { _, _, _ in false }
        }

        await store.send(.parseButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(.parseCompleted(validTerms: [parsed], invalidLines: [], hasDuplicates: false)) {
            $0.parsedTerms = [parsed]
            $0.isLoading = false
            $0.isParsed = true
        }
    }

    func testParseButtonTappedWithEmptyTextDoesNothing() async throws {
        let store = TestStore(initialState: AddTermsFeature.State()) {
            AddTermsFeature()
        }

        await store.send(.parseButtonTapped)
    }

    func testParseWithInvalidLinesStoresThemSeparately() async throws {
        let valid = ParsedTerm(termText: "apple", translation: "яблуко")
        let invalid = InvalidLine(lineNumber: 2, content: "invalid line")
        let result = ImportResult(validTerms: [valid], invalidLines: [invalid])

        let store = TestStore(initialState: AddTermsFeature.State(inputText: "apple - яблуко\ninvalid line")) {
            AddTermsFeature()
        } withDependencies: {
            $0.importClient.parse = { _ in result }
            $0.persistenceClient.termExists = { _, _, _ in false }
        }

        await store.send(.parseButtonTapped) { $0.isLoading = true }
        await store.receive(.parseCompleted(validTerms: [valid], invalidLines: [invalid], hasDuplicates: false)) {
            $0.parsedTerms = [valid]
            $0.invalidLines = [invalid]
            $0.isLoading = false
            $0.isParsed = true
        }
    }

    // MARK: - Remove term

    func testRemoveTermTapped() async throws {
        let term1 = ParsedTerm(termText: "apple", translation: "яблуко")
        let term2 = ParsedTerm(termText: "banana", translation: "банан")

        let store = TestStore(
            initialState: AddTermsFeature.State(parsedTerms: [term1, term2], isParsed: true)
        ) {
            AddTermsFeature()
        }

        await store.send(.removeTermTapped(term1.id)) {
            $0.parsedTerms = [term2]
        }
    }

    // MARK: - Save

    func testSaveButtonTappedSavesTermsAndNotifiesDelegate() async throws {
        let parsed = ParsedTerm(termText: "apple", translation: "яблуко")
        var savedTerms: [Term] = []
        let testUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let testDate = Date(timeIntervalSince1970: 1234567890)

        let store = TestStore(
            initialState: AddTermsFeature.State(parsedTerms: [parsed], isParsed: true)
        ) {
            AddTermsFeature()
        } withDependencies: {
            $0.persistenceClient.addTerms = { _, terms in savedTerms.append(contentsOf: terms) }
            $0.uuid = .constant(testUUID)
            $0.date = .constant(testDate)
        }

        await store.send(.saveButtonTapped) { $0.isLoading = true }

        await store.receive(.saveCompleted) { $0.isLoading = false }

        await store.receive(.delegate(.termsSaved))

        XCTAssertEqual(savedTerms.count, 1)
        XCTAssertEqual(savedTerms[0].id, testUUID)
        XCTAssertEqual(savedTerms[0].termText, "apple")
        XCTAssertEqual(savedTerms[0].translation, "яблуко")
        XCTAssertEqual(savedTerms[0].createdAt, testDate)
        XCTAssertEqual(savedTerms[0].updatedAt, testDate)
        XCTAssertEqual(savedTerms[0].status, .new)
    }

    func testSaveButtonTappedWithEmptyListDoesNothing() async throws {
        let store = TestStore(
            initialState: AddTermsFeature.State(isParsed: true)
        ) {
            AddTermsFeature()
        }

        await store.send(.saveButtonTapped)
    }

    // MARK: - Duplicate filtering on parse

    func testDuplicateTermsAreFilteredOutOnParse() async throws {
        let existing = Term(
            id: UUID(),
            termText: "apple",
            translation: "яблуко",
            hint: nil,
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: Date(),
            updatedAt: Date(),
            status: .new
        )
        let parsed = ParsedTerm(termText: "apple", translation: "яблуко")
        let result = ImportResult(validTerms: [parsed], invalidLines: [])

        let store = TestStore(
            initialState: AddTermsFeature.State(inputText: "apple - яблуко")
        ) {
            AddTermsFeature()
        } withDependencies: {
            $0.importClient.parse = { _ in result }
            $0.persistenceClient.termExists = { _, termText, translation in
                termText.lowercased() == existing.termText.lowercased() &&
                translation.lowercased() == existing.translation.lowercased()
            }
        }

        await store.send(.parseButtonTapped) { $0.isLoading = true }
        await store.receive(.parseCompleted(validTerms: [], invalidLines: [], hasDuplicates: true)) {
            $0.parsedTerms = []
            $0.hasDuplicates = true
            $0.isLoading = false
            $0.isParsed = true
        }
    }

    func testPartialDuplicatesAreFilteredOutAndOnlyNewRemain() async throws {
        let existing = Term(
            id: UUID(),
            termText: "apple",
            translation: "яблуко",
            hint: nil,
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: Date(),
            updatedAt: Date(),
            status: .new
        )
        let duplicate = ParsedTerm(termText: "apple", translation: "яблуко")
        let newTerm = ParsedTerm(termText: "banana", translation: "банан")
        let result = ImportResult(validTerms: [duplicate, newTerm], invalidLines: [])
        var savedTerms: [Term] = []

        let testUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let testDate = Date(timeIntervalSince1970: 1234567890)

        let store = TestStore(
            initialState: AddTermsFeature.State(inputText: "apple - яблуко\nbanana - банан")
        ) {
            AddTermsFeature()
        } withDependencies: {
            $0.importClient.parse = { _ in result }
            $0.persistenceClient.termExists = { _, termText, translation in
                termText.lowercased() == existing.termText.lowercased() &&
                translation.lowercased() == existing.translation.lowercased()
            }
            $0.persistenceClient.addTerms = { _, terms in savedTerms.append(contentsOf: terms) }
            $0.uuid = .constant(testUUID)
            $0.date = .constant(testDate)
        }

        await store.send(.parseButtonTapped) { $0.isLoading = true }
        await store.receive(.parseCompleted(validTerms: [newTerm], invalidLines: [], hasDuplicates: true)) {
            $0.parsedTerms = [newTerm]
            $0.hasDuplicates = true
            $0.isLoading = false
            $0.isParsed = true
        }

        await store.send(.saveButtonTapped) { $0.isLoading = true }
        await store.receive(.saveCompleted) { $0.isLoading = false }
        await store.receive(.delegate(.termsSaved))

        XCTAssertEqual(savedTerms.count, 1)
        XCTAssertEqual(savedTerms[0].termText, "banana")
    }

    func testDuplicateTermsWithinImportListAreFilteredOut() async throws {
        let term1 = ParsedTerm(termText: "apple", translation: "яблуко")
        let term2 = ParsedTerm(termText: "apple", translation: "яблуко")
        let result = ImportResult(validTerms: [term1, term2], invalidLines: [])
        var savedTerms: [Term] = []

        let testUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let testDate = Date(timeIntervalSince1970: 1234567890)

        let store = TestStore(
            initialState: AddTermsFeature.State(inputText: "apple - яблуко\napple - яблуко")
        ) {
            AddTermsFeature()
        } withDependencies: {
            $0.importClient.parse = { _ in result }
            $0.persistenceClient.termExists = { _, _, _ in false }
            $0.persistenceClient.addTerms = { _, terms in savedTerms.append(contentsOf: terms) }
            $0.uuid = .constant(testUUID)
            $0.date = .constant(testDate)
        }

        await store.send(.parseButtonTapped) { $0.isLoading = true }
        await store.receive(.parseCompleted(validTerms: [term1], invalidLines: [], hasDuplicates: true)) {
            $0.parsedTerms = [term1]
            $0.hasDuplicates = true
            $0.isLoading = false
            $0.isParsed = true
        }

        await store.send(.saveButtonTapped) { $0.isLoading = true }
        await store.receive(.saveCompleted) { $0.isLoading = false }
        await store.receive(.delegate(.termsSaved))

        XCTAssertEqual(savedTerms.count, 1)
        XCTAssertEqual(savedTerms[0].termText, "apple")
    }
}
