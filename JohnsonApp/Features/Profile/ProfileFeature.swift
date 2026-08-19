//
//  ProfileFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation


@Reducer
struct ProfileFeature {

    @ObservableState
    struct State: Equatable {
        var username: String = "user"
        var userStreak: Int = 0

        var sessions: [LanguageSession] = []
        var activeSessionId: UUID? = nil

        var activeSession: LanguageSession? {
            guard let activeSessionId else { return nil }
            return sessions.first(where: { $0.id == activeSessionId })
        }

        @Presents var addSession: CreateSessionFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        init(
            username: String = "user",
            userStreak: Int = 0,
            sessions: [LanguageSession] = [],
            activeSessionId: UUID? = nil,
            addSession: CreateSessionFeature.State? = nil,
            alert: AlertState<Action.Alert>? = nil
        ) {
            self.username = username
            self.userStreak = userStreak
            self.sessions = sessions
            self.activeSessionId = activeSessionId
            self.addSession = addSession
            self.alert = alert
        }
    }

    enum Action: Equatable {
        case onAppear
        case fetchSessionsSuccess(sessions: [LanguageSession], activeSessionId: UUID?)
        case sessionTapped(LanguageSession)
        case addSessionButtonTapped
        case addSession(PresentationAction<CreateSessionFeature.Action>)
        case deleteSessionButtonTapped(LanguageSession)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {
            case confirmDelete(LanguageSession)
        }

        @CasePathable
        enum Delegate: Equatable {
            case activeSessionChanged(LanguageSession)
            case sessionDeleted(remainingSessions: [LanguageSession])
        }
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                return .run { [userDefaultsClient, persistenceClient] send in
                    do {
                        let sessions = try await persistenceClient.fetchSessions()
                        let activeId = userDefaultsClient.activeSessionId()
                        await send(.fetchSessionsSuccess(sessions: sessions, activeSessionId: activeId))
                    } catch {
                        await send(.fetchSessionsSuccess(sessions: [], activeSessionId: nil))
                    }
                }

            case let .fetchSessionsSuccess(sessions, activeId):
                state.sessions = sessions
                if let activeId, sessions.contains(where: { $0.id == activeId }) {
                    state.activeSessionId = activeId
                } else {
                    state.activeSessionId = sessions.first?.id
                }
                return .none

            case let .sessionTapped(session):
                guard session.id != state.activeSessionId else { return .none }
                state.activeSessionId = session.id
                userDefaultsClient.setActiveSessionId(session.id)
                return .send(.delegate(.activeSessionChanged(session)))

            case .addSessionButtonTapped:
                state.addSession = CreateSessionFeature.State()
                return .none

            case let .addSession(.presented(.delegate(.sessionCreated(newSession)))):
                state.addSession = nil
                state.sessions.append(newSession)
                state.activeSessionId = newSession.id
                userDefaultsClient.setActiveSessionId(newSession.id)
                return .send(.delegate(.activeSessionChanged(newSession)))

            case .addSession:
                return .none

            case let .deleteSessionButtonTapped(session):
                let sessionName = session.name
                state.alert = AlertState {
                    TextState("Видалити сесію?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(session)) {
                        TextState("Видалити")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Скасувати")
                    }
                } message: {
                    TextState("Ви впевнені, що хочете видалити сесію \"\(sessionName)\"? Усі картки та прогрес цієї сесії будуть видалені.")
                }
                return .none

            case let .alert(.presented(.confirmDelete(session))):
                state.alert = nil
                let targetId = session.id
                let wasActive = (targetId == state.activeSessionId)
                return .run { [userDefaultsClient, persistenceClient] send in
                    do {
                        try await persistenceClient.deleteSession(targetId)
                        let remaining = try await persistenceClient.fetchSessions()

                        if remaining.isEmpty {
                            userDefaultsClient.setActiveSessionId(nil)
                            await send(.fetchSessionsSuccess(sessions: [], activeSessionId: nil))
                            await send(.delegate(.sessionDeleted(remainingSessions: [])))
                        } else if wasActive, let nextActive = remaining.first {
                            userDefaultsClient.setActiveSessionId(nextActive.id)
                            await send(.fetchSessionsSuccess(sessions: remaining, activeSessionId: nextActive.id))
                            await send(.delegate(.activeSessionChanged(nextActive)))
                        } else {
                            let activeId = userDefaultsClient.activeSessionId()
                            await send(.fetchSessionsSuccess(sessions: remaining, activeSessionId: activeId))
                            await send(.delegate(.sessionDeleted(remainingSessions: remaining)))
                        }
                    } catch {
                        
                    }
                }

            case .alert:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$addSession, action: \.addSession) {
            CreateSessionFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
