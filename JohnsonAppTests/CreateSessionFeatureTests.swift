//
//  CreateSessionFeatureTests.swift
//  JohnsonAppTests
//

import ComposableArchitecture
import XCTest
@testable import JohnsonApp

@MainActor
final class CreateSessionFeatureTests: XCTestCase {

    private let testUUID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    private let testDate = Date(timeIntervalSince1970: 1_000_000)

    // MARK: - Field Changes

    func testNameChanged() async throws {
        let store = TestStore(initialState: CreateSessionFeature.State()) {
            CreateSessionFeature()
        }
        await store.send(.nameChanged("My Session")) {
            $0.name = "My Session"
            $0.validationError = nil
        }
    }

    func testTermLanguageChanged() async throws {
        let store = TestStore(initialState: CreateSessionFeature.State()) {
            CreateSessionFeature()
        }
        await store.send(.termLanguageChanged(.ukrainian)) {
            $0.termLanguage = .ukrainian
            $0.validationError = nil
        }
    }

    func testTranslationLanguageChanged() async throws {
        let store = TestStore(initialState: CreateSessionFeature.State()) {
            CreateSessionFeature()
        }
        await store.send(.translationLanguageChanged(.english)) {
            $0.translationLanguage = .english
            $0.validationError = nil
        }
    }

    // MARK: - Validation

    func testSubmitWithEmptyNameShowsError() async throws {
        let store = TestStore(initialState: CreateSessionFeature.State(name: "   ")) {
            CreateSessionFeature()
        }
        await store.send(.submitTapped) {
            $0.validationError = "Назва сесії не може бути порожньою"
        }
    }

    func testFieldChangeAfterErrorClearsError() async throws {
        let store = TestStore(
            initialState: CreateSessionFeature.State(
                validationError: "Помилка"
            )
        ) {
            CreateSessionFeature()
        }
        await store.send(.nameChanged("New")) {
            $0.name = "New"
            $0.validationError = nil
        }
    }

    // MARK: - Submit Success

    func testSubmitWithValidDataCreatesSessionAndNotifiesDelegate() async throws {
        var savedSession: LanguageSession?

        let store = TestStore(
            initialState: CreateSessionFeature.State(
                name: "English Travel",
                termLanguage: .english,
                translationLanguage: .ukrainian
            )
        ) {
            CreateSessionFeature()
        } withDependencies: {
            $0.persistenceClient.addSession = { session in savedSession = session }
            $0.uuid = .constant(testUUID)
            $0.date = .constant(testDate)
        }

        let expectedSession = LanguageSession(
            id: testUUID,
            name: "English Travel",
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: testDate
        )

        await store.send(.submitTapped) {
            $0.isSubmitting = true
            $0.validationError = nil
        }

        await store.receive(.submitSuccess(expectedSession)) {
            $0.isSubmitting = false
        }

        await store.receive(.delegate(.sessionCreated(expectedSession)))

        XCTAssertEqual(savedSession?.id, testUUID)
        XCTAssertEqual(savedSession?.name, "English Travel")
        XCTAssertEqual(savedSession?.termLanguage, .english)
        XCTAssertEqual(savedSession?.translationLanguage, .ukrainian)
    }

    func testSubmitTrimsWhitespaceFromName() async throws {
        var savedName: String?

        let store = TestStore(
            initialState: CreateSessionFeature.State(
                name: "  My Session  ",
                termLanguage: .english,
                translationLanguage: .ukrainian
            )
        ) {
            CreateSessionFeature()
        } withDependencies: {
            $0.persistenceClient.addSession = { session in savedName = session.name }
            $0.uuid = .constant(testUUID)
            $0.date = .constant(testDate)
        }

        await store.send(.submitTapped) { $0.isSubmitting = true }
        await store.receive(.submitSuccess(.init(
            id: testUUID,
            name: "My Session",
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: testDate
        ))) { $0.isSubmitting = false }
        await store.receive(.delegate(.sessionCreated(.init(
            id: testUUID,
            name: "My Session",
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: testDate
        ))))

        XCTAssertEqual(savedName, "My Session")
    }

    // MARK: - Submit Failure

    func testSubmitFailureShowsError() async throws {
        struct SaveError: Error {}

        let store = TestStore(
            initialState: CreateSessionFeature.State(
                name: "Test",
                termLanguage: .english,
                translationLanguage: .ukrainian
            )
        ) {
            CreateSessionFeature()
        } withDependencies: {
            $0.persistenceClient.addSession = { _ in throw SaveError() }
            $0.uuid = .constant(testUUID)
            $0.date = .constant(testDate)
        }

        await store.send(.submitTapped) { $0.isSubmitting = true }
        await store.receive(.submitFailure(SaveError().localizedDescription)) {
            $0.isSubmitting = false
            $0.validationError = SaveError().localizedDescription
        }
    }

    // MARK: - canSubmit Logic

    func testCanSubmitIsFalseWhenNameIsEmpty() {
        let state = CreateSessionFeature.State(
            name: "",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        XCTAssertFalse(state.canSubmit)
    }

    func testCanSubmitIsTrueWhenSameLanguages() {
        // Same language is allowed — e.g. monolingual vocab study
        let state = CreateSessionFeature.State(
            name: "Test",
            termLanguage: .english,
            translationLanguage: .english
        )
        XCTAssertTrue(state.canSubmit)
    }

    func testCanSubmitIsFalseWhenSubmitting() {
        let state = CreateSessionFeature.State(
            name: "Test",
            termLanguage: .english,
            translationLanguage: .ukrainian,
            isSubmitting: true
        )
        XCTAssertFalse(state.canSubmit)
    }

    func testCanSubmitIsTrueWithValidData() {
        let state = CreateSessionFeature.State(
            name: "Test",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        XCTAssertTrue(state.canSubmit)
    }
}
