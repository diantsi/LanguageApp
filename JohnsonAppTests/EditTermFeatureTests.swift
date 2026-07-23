//
//  EditTermFeatureTests.swift
//  JohnsonApp
//

import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import JohnsonApp

@MainActor
final class EditTermFeatureTests: XCTestCase {

    // MARK: - Helpers

    private func makeTerm(
        termText: String = "apple",
        translation: String = "яблуко",
        hint: String? = nil
    ) -> Term {
        Term(
            id: UUID(),
            termText: termText,
            translation: translation,
            hint: hint,
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_000_000),
            status: .new
        )
    }

    // MARK: - Tests

    func testInitialState() async throws {
        let term = makeTerm(termText: "apple", translation: "яблуко", hint: "fruit")

        let store = TestStore(initialState: EditTermFeature.State(term: term)) {
            EditTermFeature()
        }

        XCTAssertEqual(store.state.id, term.id)
        XCTAssertEqual(store.state.termText, "apple")
        XCTAssertEqual(store.state.translation, "яблуко")
        XCTAssertEqual(store.state.hint, "fruit")
        XCTAssertEqual(store.state.termLanguage, .english)
        XCTAssertEqual(store.state.translationLanguage, .ukrainian)
        XCTAssertFalse(store.state.isEditing)
        XCTAssertFalse(store.state.isLoading)
    }

    func testTextChangedActions() async throws {
        let store = TestStore(initialState: EditTermFeature.State(term: makeTerm())) {
            EditTermFeature()
        }

        await store.send(.termTextChanged("banana")) { $0.termText = "banana" }
        await store.send(.translationChanged("банан")) { $0.translation = "банан" }
        await store.send(.hintChanged("another fruit")) { $0.hint = "another fruit" }
    }

    func testEditButtonTapped() async throws {
        let store = TestStore(initialState: EditTermFeature.State(term: makeTerm())) {
            EditTermFeature()
        }

        await store.send(.editButtonTapped) { $0.isEditing = true }
    }

    func testCloseButtonDismisses() async throws {
        let isDismissed = LockIsolated(false)
        let store = TestStore(initialState: EditTermFeature.State(term: makeTerm())) {
            EditTermFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { isDismissed.setValue(true) }
        }

        await store.send(.closeButtonTapped)
        XCTAssertTrue(isDismissed.value)
    }

    func testCanSaveLogic() async throws {
        var state = EditTermFeature.State(term: makeTerm())

        XCTAssertTrue(state.canSave)

        state.termText = ""
        XCTAssertFalse(state.canSave)

        state.termText = "apple"
        state.translation = ""
        XCTAssertFalse(state.canSave)

        state.translation = "яблуко"
        XCTAssertTrue(state.canSave)
    }

    func testSaveSuccess() async throws {
        let term = makeTerm()
        let savedTermText = LockIsolated<String?>(nil)
        let savedTranslation = LockIsolated<String?>(nil)
        let savedId = LockIsolated<UUID?>(nil)

        let store = TestStore(initialState: EditTermFeature.State(term: term)) {
            EditTermFeature()
        } withDependencies: {
            $0.persistenceClient.updateTerm = { saved in
                savedId.setValue(saved.id)
                savedTermText.setValue(saved.termText)
                savedTranslation.setValue(saved.translation)
            }
        }

        await store.send(.editButtonTapped) { $0.isEditing = true }
        await store.send(.termTextChanged("apple pie")) { $0.termText = "apple pie" }
        await store.send(.saveButtonTapped) { $0.isLoading = true }
        await store.receive(.saveCompleted) {
            $0.isLoading = false
            $0.isEditing = false
        }
        await store.receive(.delegate(.termSaved))

        XCTAssertEqual(savedId.value, term.id)
        XCTAssertEqual(savedTermText.value, "apple pie")
        XCTAssertEqual(savedTranslation.value, "яблуко")
    }

    func testSaveFailure() async throws {
        struct SomeError: Error, LocalizedError {
            var errorDescription: String? { "Failed to save" }
        }

        let store = TestStore(initialState: EditTermFeature.State(term: makeTerm())) {
            EditTermFeature()
        } withDependencies: {
            $0.persistenceClient.updateTerm = { _ in throw SomeError() }
        }

        await store.send(.editButtonTapped) { $0.isEditing = true }
        await store.send(.saveButtonTapped) { $0.isLoading = true }
        await store.receive(.saveFailure("Failed to save")) { $0.isLoading = false }
    }

    func testDeleteFlow() async throws {
        let term = makeTerm()
        let deletedIdReceived = LockIsolated<UUID?>(nil)

        let store = TestStore(initialState: EditTermFeature.State(term: term)) {
            EditTermFeature()
        } withDependencies: {
            $0.persistenceClient.deleteTerm = { id in deletedIdReceived.setValue(id) }
        }

        await store.send(.deleteButtonTapped) {
            $0.alert = AlertState {
                TextState("Видалити термін?")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete) {
                    TextState("Видалити")
                }
                ButtonState(role: .cancel) {
                    TextState("Скасувати")
                }
            } message: {
                TextState("Ви впевнені, що хочете видалити термін \"apple\"?")
            }
        }

        await store.send(.alert(.presented(.confirmDelete))) {
            $0.alert = nil
            $0.isLoading = true
        }

        await store.receive(.delegate(.termDeleted))

        XCTAssertEqual(deletedIdReceived.value, term.id)
    }
}
