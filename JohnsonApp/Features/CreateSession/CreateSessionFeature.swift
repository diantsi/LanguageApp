//
//  CreateSessionFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation


@Reducer
struct CreateSessionFeature {

    @ObservableState
    struct State: Equatable {
        var name: String = ""
        var termLanguage: Language = .english
        var translationLanguage: Language = .ukrainian
        var isSubmitting: Bool = false
        var validationError: String? = nil

        var canSubmit: Bool {
            !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !isSubmitting
        }
    }

    enum Action: Equatable {
        case nameChanged(String)
        case termLanguageChanged(Language)
        case translationLanguageChanged(Language)
        case submitTapped
        case submitSuccess(LanguageSession)
        case submitFailure(String)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case sessionCreated(LanguageSession)
        }
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .nameChanged(let name):
                state.name = name
                state.validationError = nil
                return .none

            case .termLanguageChanged(let lang):
                state.termLanguage = lang
                state.validationError = nil
                return .none

            case .translationLanguageChanged(let lang):
                state.translationLanguage = lang
                state.validationError = nil
                return .none

            case .submitTapped:
                let trimmedName = state.name.trimmingCharacters(in: .whitespaces)
                guard !trimmedName.isEmpty else {
                    state.validationError = "Назва сесії не може бути порожньою"
                    return .none
                }
                state.isSubmitting = true
                state.validationError = nil
                let session = LanguageSession(
                    id: uuid(),
                    name: trimmedName,
                    termLanguage: state.termLanguage,
                    translationLanguage: state.translationLanguage,
                    createdAt: date.now
                )
                return .run { send in
                    do {
                        try await persistenceClient.addSession(session)
                        await send(.submitSuccess(session))
                    } catch {
                        await send(.submitFailure(error.localizedDescription))
                    }
                }

            case .submitSuccess(let session):
                state.isSubmitting = false
                return .send(.delegate(.sessionCreated(session)))

            case .submitFailure(let message):
                state.isSubmitting = false
                state.validationError = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
