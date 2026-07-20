//
//  EditTermFeatureTests.swift
//  JohnsonApp
//
//

import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import JohnsonApp

@MainActor
final class EditTermFeatureTests: XCTestCase {

    func testInitialState() async throws {
        let term = Term(
            termText: "apple",
            translation: "яблуко",
            hint: "fruit",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        
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
        let term = Term(
            termText: "apple",
            translation: "яблуко",
            hint: "fruit",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        
        let store = TestStore(initialState: EditTermFeature.State(term: term)) {
            EditTermFeature()
        }

        await store.send(.termTextChanged("banana")) {
            $0.termText = "banana"
        }
        await store.send(.translationChanged("банан")) {
            $0.translation = "банан"
        }
        await store.send(.hintChanged("another fruit")) {
            $0.hint = "another fruit"
        }
    }

    func testEditButtonTapped() async throws {
        let term = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        
        let store = TestStore(initialState: EditTermFeature.State(term: term)) {
            EditTermFeature()
        }

        await store.send(.editButtonTapped) {
            $0.isEditing = true
        }
    }

    func testCloseButtonDismisses() async throws {
        let term = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        
        let isDismissed = LockIsolated(false)
        let store = TestStore(initialState: EditTermFeature.State(term: term)) {
            EditTermFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                isDismissed.setValue(true)
            }
        }

        await store.send(.closeButtonTapped)
        XCTAssertTrue(isDismissed.value)
    }

    func testCanSaveLogic() async throws {
        let term = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        
        var state = EditTermFeature.State(term: term)
        
        // Initial values are not empty, canSave is true (we simplified so that canSave is true if fields are not empty)
        XCTAssertTrue(state.canSave)
        
        // Empty termText makes canSave false
        state.termText = ""
        XCTAssertFalse(state.canSave)
        
        // Empty translation makes canSave false
        state.termText = "apple"
        state.translation = ""
        XCTAssertFalse(state.canSave)
        
        // Non-empty makes it true again
        state.translation = "яблуко"
        XCTAssertTrue(state.canSave)
    }

    func testSaveSuccess() async throws {
        let term = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        
        let savedTermText = LockIsolated<String?>(nil)
        let savedTranslation = LockIsolated<String?>(nil)
        let savedId = LockIsolated<UUID?>(nil)
        
        let store = TestStore(initialState: EditTermFeature.State(term: term)) {
            EditTermFeature()
        } withDependencies: {
            $0.persistenceClient.updateTerm = { term in
                savedId.setValue(term.id)
                savedTermText.setValue(term.termText)
                savedTranslation.setValue(term.translation)
            }
        }

        await store.send(.editButtonTapped) {
            $0.isEditing = true
        }
        
        await store.send(.termTextChanged("apple pie")) {
            $0.termText = "apple pie"
        }

        await store.send(.saveButtonTapped) {
            $0.isLoading = true
        }

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
        let term = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        
        let store = TestStore(initialState: EditTermFeature.State(term: term)) {
            EditTermFeature()
        } withDependencies: {
            struct SomeError: Error, LocalizedError {
                var errorDescription: String? { "Failed to save" }
            }
            $0.persistenceClient.updateTerm = { _ in
                throw SomeError()
            }
        }

        await store.send(.editButtonTapped) {
            $0.isEditing = true
        }

        await store.send(.saveButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(.saveFailure("Failed to save")) {
            $0.isLoading = false
        }
    }

    func testDeleteFlow() async throws {
        let term = Term(
            termText: "apple",
            translation: "яблуко",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        
        let deletedIdReceived = LockIsolated<UUID?>(nil)
        
        let store = TestStore(initialState: EditTermFeature.State(term: term)) {
            EditTermFeature()
        } withDependencies: {
            $0.persistenceClient.deleteTerm = { id in
                deletedIdReceived.setValue(id)
            }
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
