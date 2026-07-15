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
        }

        await store.send(.parseButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(.parseCompleted(result)) {
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
        }

        await store.send(.parseButtonTapped) { $0.isLoading = true }
        await store.receive(.parseCompleted(result)) {
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
        let term = ParsedTerm(termText: "apple", translation: "яблуко")
        var savedTerms: [Term] = []

        let store = TestStore(
            initialState: AddTermsFeature.State(parsedTerms: [term], isParsed: true)
        ) {
            AddTermsFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _ in [] }
            $0.persistenceClient.addTerm = { savedTerms.append($0) }
        }

        await store.send(.saveButtonTapped) { $0.isLoading = true }

        await store.receive(.duplicatesChecked([])) // no duplicates — no state change

        await store.receive(.saveCompleted) { $0.isLoading = false }

        await store.receive(.delegate(.termsSaved))

        XCTAssertEqual(savedTerms.count, 1)
        XCTAssertEqual(savedTerms[0].termText, "apple")
        XCTAssertEqual(savedTerms[0].translation, "яблуко")
    }

    func testSaveButtonTappedWithEmptyListDoesNothing() async throws {
        let store = TestStore(
            initialState: AddTermsFeature.State(isParsed: true)
        ) {
            AddTermsFeature()
        }

        await store.send(.saveButtonTapped)
    }

    // MARK: - Duplicate detection

    func testDuplicateTermsAreSkippedOnSave() async throws {
        let existing = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        let parsed = ParsedTerm(termText: "apple", translation: "яблуко")
        var savedTerms: [Term] = []

        let store = TestStore(
            initialState: AddTermsFeature.State(parsedTerms: [parsed], isParsed: true)
        ) {
            AddTermsFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _ in [existing] }
            $0.persistenceClient.addTerm = { savedTerms.append($0) }
        }

        await store.send(.saveButtonTapped) { $0.isLoading = true }

        await store.receive(.duplicatesChecked([parsed.id])) {
            $0.duplicateIDs = [parsed.id]
            $0.isLoading = false
        }

        XCTAssertTrue(savedTerms.isEmpty)
    }

    func testPartialDuplicatesOnlySavesNewTerms() async throws {
        let existing = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        let duplicate = ParsedTerm(termText: "apple", translation: "яблуко")
        let newTerm = ParsedTerm(termText: "banana", translation: "банан")
        var savedTerms: [Term] = []

        let store = TestStore(
            initialState: AddTermsFeature.State(parsedTerms: [duplicate, newTerm], isParsed: true)
        ) {
            AddTermsFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _ in [existing] }
            $0.persistenceClient.addTerm = { savedTerms.append($0) }
        }

        await store.send(.saveButtonTapped) { $0.isLoading = true }

        await store.receive(.duplicatesChecked([duplicate.id])) {
            $0.duplicateIDs = [duplicate.id]
        }

        await store.receive(.saveCompleted) { $0.isLoading = false }

        await store.receive(.delegate(.termsSaved))

        XCTAssertEqual(savedTerms.count, 1)
        XCTAssertEqual(savedTerms[0].termText, "banana")
    }

    // MARK: - findDuplicateIDs

    func testFindDuplicateIDsCaseInsensitive() {
        let parsed = ParsedTerm(termText: "Apple", translation: "Яблуко")
        let existing = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )

        let ids = AddTermsFeature.findDuplicateIDs(among: [parsed], existing: [existing])
        XCTAssertEqual(ids, [parsed.id])
    }

    func testFindDuplicateIDsNonMatchingTermsAreNotDuplicates() {
        let parsed = ParsedTerm(termText: "cherry", translation: "вишня")
        let existing = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )

        let ids = AddTermsFeature.findDuplicateIDs(among: [parsed], existing: [existing])
        XCTAssertTrue(ids.isEmpty)
    }

    func testFindDuplicateIDsSameTermDifferentTranslationIsNotDuplicate() {
        let parsed = ParsedTerm(termText: "bank", translation: "банк")
        let existing = Term(
            termText: "bank",
            translation: "берег",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )

        let ids = AddTermsFeature.findDuplicateIDs(among: [parsed], existing: [existing])
        XCTAssertTrue(ids.isEmpty)
    }
}
