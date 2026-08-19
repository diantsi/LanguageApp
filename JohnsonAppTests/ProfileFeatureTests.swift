//
//  ProfileFeatureTests.swift
//  JohnsonAppTests
//

import ComposableArchitecture
import XCTest
@testable import JohnsonApp

@MainActor
final class ProfileFeatureTests: XCTestCase {

    private let session1 = LanguageSession(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "English Travel",
        termLanguage: .english,
        translationLanguage: .ukrainian,
        createdAt: Date(timeIntervalSince1970: 1_000_000)
    )

    private let session2 = LanguageSession(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Polish Work",
        termLanguage: .polish,
        translationLanguage: .ukrainian,
        createdAt: Date(timeIntervalSince1970: 2_000_000)
    )

    // MARK: - OnAppear

    func testOnAppearFetchesSessionsAndSetsActiveSessionId() async throws {
        let store = TestStore(initialState: ProfileFeature.State()) {
            ProfileFeature()
        } withDependencies: {
            $0.persistenceClient.fetchSessions = { [self.session1, self.session2] }
            $0.userDefaultsClient.activeSessionId = { self.session2.id }
        }

        await store.send(.onAppear)

        await store.receive(.fetchSessionsSuccess(sessions: [session1, session2], activeSessionId: session2.id)) {
            $0.sessions = [self.session1, self.session2]
            $0.activeSessionId = self.session2.id
            XCTAssertEqual($0.activeSession, self.session2)
        }
    }

    // MARK: - Switch Session

    func testSessionTappedSwitchesActiveSessionAndNotifiesDelegate() async throws {
        var savedActiveId: UUID?

        let store = TestStore(
            initialState: ProfileFeature.State(
                sessions: [session1, session2],
                activeSessionId: session1.id
            )
        ) {
            ProfileFeature()
        } withDependencies: {
            $0.userDefaultsClient.setActiveSessionId = { id in savedActiveId = id }
        }

        await store.send(.sessionTapped(session2)) {
            $0.activeSessionId = self.session2.id
        }

        await store.receive(.delegate(.activeSessionChanged(session2)))
        XCTAssertEqual(savedActiveId, session2.id)
    }

    func testSessionTappedSameActiveSessionDoesNothing() async throws {
        let store = TestStore(
            initialState: ProfileFeature.State(
                sessions: [session1, session2],
                activeSessionId: session1.id
            )
        ) {
            ProfileFeature()
        }

        await store.send(.sessionTapped(session1))
    }

    // MARK: - Add Session Sheet Flow

    func testAddSessionButtonTappedOpensSheet() async throws {
        let store = TestStore(initialState: ProfileFeature.State()) {
            ProfileFeature()
        }

        await store.send(.addSessionButtonTapped) {
            $0.addSession = CreateSessionFeature.State()
        }
    }

    func testAddSessionCreatedNotifiesDelegateAndSelectsNewSession() async throws {
        var savedActiveId: UUID?
        let newSession = LanguageSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "French Vocab",
            termLanguage: .french,
            translationLanguage: .english,
            createdAt: Date()
        )

        let store = TestStore(
            initialState: ProfileFeature.State(
                sessions: [session1],
                activeSessionId: session1.id,
                addSession: CreateSessionFeature.State()
            )
        ) {
            ProfileFeature()
        } withDependencies: {
            $0.userDefaultsClient.setActiveSessionId = { id in savedActiveId = id }
        }

        await store.send(.addSession(.presented(.delegate(.sessionCreated(newSession))))) {
            $0.addSession = nil
            $0.sessions = [self.session1, newSession]
            $0.activeSessionId = newSession.id
        }

        await store.receive(.delegate(.activeSessionChanged(newSession)))
        XCTAssertEqual(savedActiveId, newSession.id)
    }

    // MARK: - Delete Session Flow

    func testDeleteSessionButtonTappedPresentsAlert() async throws {
        let store = TestStore(
            initialState: ProfileFeature.State(
                sessions: [session1],
                activeSessionId: session1.id
            )
        ) {
            ProfileFeature()
        }

        await store.send(.deleteSessionButtonTapped(session1)) {
            $0.alert = AlertState {
                TextState("Видалити сесію?")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(self.session1)) {
                    TextState("Видалити")
                }
                ButtonState(role: .cancel) {
                    TextState("Скасувати")
                }
            } message: {
                TextState("Ви впевнені, що хочете видалити сесію \"\(self.session1.name)\"? Усі картки та прогрес цієї сесії будуть видалені.")
            }
        }
    }

    func testConfirmDeleteActiveSessionSwitchesToNextSession() async throws {
        var deletedId: UUID?
        var savedActiveId: UUID?

        let store = TestStore(
            initialState: ProfileFeature.State(
                sessions: [session1, session2],
                activeSessionId: session1.id
            )
        ) {
            ProfileFeature()
        } withDependencies: {
            $0.persistenceClient.deleteSession = { id in deletedId = id }
            $0.persistenceClient.fetchSessions = { [self.session2] }
            $0.userDefaultsClient.setActiveSessionId = { id in savedActiveId = id }
        }

        await store.send(.deleteSessionButtonTapped(session1)) {
            $0.alert = AlertState {
                TextState("Видалити сесію?")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(self.session1)) {
                    TextState("Видалити")
                }
                ButtonState(role: .cancel) {
                    TextState("Скасувати")
                }
            } message: {
                TextState("Ви впевнені, що хочете видалити сесію \"\(self.session1.name)\"? Усі картки та прогрес цієї сесії будуть видалені.")
            }
        }

        await store.send(.alert(.presented(.confirmDelete(session1)))) {
            $0.alert = nil
        }

        await store.receive(.fetchSessionsSuccess(sessions: [session2], activeSessionId: session2.id)) {
            $0.sessions = [self.session2]
            $0.activeSessionId = self.session2.id
        }

        await store.receive(.delegate(.activeSessionChanged(session2)))

        XCTAssertEqual(deletedId, session1.id)
        XCTAssertEqual(savedActiveId, session2.id)
    }

    func testConfirmDeleteLastSessionReturnsToOnboarding() async throws {
        var deletedId: UUID?
        var savedActiveId: UUID?

        let store = TestStore(
            initialState: ProfileFeature.State(
                sessions: [session1],
                activeSessionId: session1.id
            )
        ) {
            ProfileFeature()
        } withDependencies: {
            $0.persistenceClient.deleteSession = { id in deletedId = id }
            $0.persistenceClient.fetchSessions = { [] }
            $0.userDefaultsClient.setActiveSessionId = { id in savedActiveId = id }
        }

        await store.send(.deleteSessionButtonTapped(session1)) {
            $0.alert = AlertState {
                TextState("Видалити сесію?")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(self.session1)) {
                    TextState("Видалити")
                }
                ButtonState(role: .cancel) {
                    TextState("Скасувати")
                }
            } message: {
                TextState("Ви впевнені, що хочете видалити сесію \"\(self.session1.name)\"? Усі картки та прогрес цієї сесії будуть видалені.")
            }
        }

        await store.send(.alert(.presented(.confirmDelete(session1)))) {
            $0.alert = nil
        }

        await store.receive(.fetchSessionsSuccess(sessions: [], activeSessionId: nil)) {
            $0.sessions = []
            $0.activeSessionId = nil
        }

        await store.receive(.delegate(.sessionDeleted(remainingSessions: [])))

        XCTAssertEqual(deletedId, session1.id)
        XCTAssertNil(savedActiveId)
    }
}
