//
//  AppFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation


@Reducer
struct AppFeature {

    enum Tab: Equatable {
        case dictionary
        case flashcards
        case learning
        case profile
    }

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .dictionary

        var activeSession: LanguageSession? = nil
        var isLoading: Bool = true

        var createSession: CreateSessionFeature.State = CreateSessionFeature.State()

        var dictionary  = DictionaryFeature.State()
        var flashcard   = FlashcardFeature.State()
        var learning    = LearningSetupFeature.State()
        var profile     = ProfileFeature.State()
    }

    enum Action: Equatable {
        case onAppear
        case sessionLoaded(LanguageSession)
        case noSessionFound
        case selectTab(Tab)

        case createSession(CreateSessionFeature.Action)
        case dictionary(DictionaryFeature.Action)
        case flashcard(FlashcardFeature.Action)
        case learning(LearningSetupFeature.Action)
        case profile(ProfileFeature.Action)
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    public var body: some Reducer<State, Action> {
        Scope(state: \.createSession, action: \.createSession) {
            CreateSessionFeature()
        }
        Scope(state: \.dictionary, action: \.dictionary) {
            DictionaryFeature()
        }
        Scope(state: \.flashcard, action: \.flashcard) {
            FlashcardFeature()
        }
        Scope(state: \.learning, action: \.learning) {
            LearningSetupFeature()
        }
        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }

        Reduce { state, action in
            switch action {

            case .onAppear:
                return .run { [userDefaultsClient] send in
                    do {
                        let sessions = try await persistenceClient.fetchSessions()
                        let savedId  = userDefaultsClient.activeSessionId()

                        if let savedId, let session = sessions.first(where: { $0.id == savedId }) {
                            await send(.sessionLoaded(session))
                        } else if let first = sessions.first {
                            await send(.sessionLoaded(first))
                        } else {
                            await send(.noSessionFound)
                        }
                    } catch {
                        await send(.noSessionFound)
                    }
                }

            case .sessionLoaded(let session):
                state.activeSession = session
                state.isLoading = false
                userDefaultsClient.setActiveSessionId(session.id)
                state.dictionary.sessionId = session.id
                state.dictionary.termLanguage = session.termLanguage
                state.dictionary.translationLanguage = session.translationLanguage
                state.flashcard.sessionId  = session.id
                state.learning.sessionId   = session.id
                state.profile.activeSessionId = session.id
                return .send(.dictionary(.onAppear))

            case .noSessionFound:
                state.activeSession = nil
                state.isLoading = false
                return .none


            case .selectTab(let tab):
                state.selectedTab = tab
                return .none


            case .createSession(.delegate(.sessionCreated(let session))):
                state.activeSession = session
                userDefaultsClient.setActiveSessionId(session.id)
                state.dictionary.sessionId = session.id
                state.dictionary.termLanguage = session.termLanguage
                state.dictionary.translationLanguage = session.translationLanguage
                state.flashcard.sessionId  = session.id
                state.learning.sessionId   = session.id
                state.profile.activeSessionId = session.id
                return .send(.dictionary(.onAppear))

            case .createSession:
                return .none


            case .dictionary:
                return .none

            case .flashcard(.delegate(.goToDictionary)):
                state.selectedTab = .dictionary
                return .none

            case .flashcard:
                return .none

            case .learning:
                return .none
                
            case .profile(.delegate(.activeSessionChanged(let newSession))):
                state.activeSession = newSession
                userDefaultsClient.setActiveSessionId(newSession.id)
                state.dictionary.sessionId = newSession.id
                state.dictionary.termLanguage = newSession.termLanguage
                state.dictionary.translationLanguage = newSession.translationLanguage
                state.flashcard.sessionId = newSession.id
                state.learning.sessionId = newSession.id
                return .send(.dictionary(.onAppear))

            case .profile(.delegate(.sessionDeleted(let remaining))):
                if remaining.isEmpty {
                    state.activeSession = nil
                }
                return .none

            case .profile:
                return .none
            }
        }
    }
}
