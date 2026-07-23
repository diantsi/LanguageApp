//
//  EditTermFeature.swift
//  JohnsonApp
//
//

import ComposableArchitecture
import Foundation

@Reducer
struct EditTermFeature {

    @ObservableState
    struct State: Equatable {
        let id: UUID
        let termLanguage: Language
        let translationLanguage: Language
        let createdAt: Date
        let status: LearningStatus

        var termText: String
        var translation: String
        var hint: String

        var isEditing: Bool = false
        var isLoading: Bool = false
        @Presents var alert: AlertState<Action.Alert>?

        var canSave: Bool {
            !termText.trimmingCharacters(in: .whitespaces).isEmpty &&
            !translation.trimmingCharacters(in: .whitespaces).isEmpty &&
            !isLoading
        }

        init(term: Term) {
            self.id = term.id
            self.termLanguage = term.termLanguage
            self.translationLanguage = term.translationLanguage
            self.createdAt = term.createdAt
            self.status = term.status
            self.termText = term.termText
            self.translation = term.translation
            self.hint = term.hint ?? ""
        }
    }

    enum Action: Equatable {
        case termTextChanged(String)
        case translationChanged(String)
        case hintChanged(String)

        case editButtonTapped
        case closeButtonTapped

        case saveButtonTapped
        case saveCompleted
        case saveFailure(String)

        case deleteButtonTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {
            case confirmDelete
        }
        enum Delegate: Equatable {
            case termSaved
            case termDeleted
        }
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .termTextChanged(text):
                state.termText = text
                return .none

            case let .translationChanged(text):
                state.translation = text
                return .none

            case let .hintChanged(text):
                state.hint = text
                return .none

            case .editButtonTapped:
                state.isEditing = true
                return .none

            case .closeButtonTapped:
                return .run { _ in await dismiss() }

            case .saveButtonTapped:
                guard state.canSave else { return .none }
                state.isLoading = true

                let term = Term(
                    id: state.id,
                    termText: state.termText.trimmingCharacters(in: .whitespaces),
                    translation: state.translation.trimmingCharacters(in: .whitespaces),
                    hint: {
                        let h = state.hint.trimmingCharacters(in: .whitespaces)
                        return h.isEmpty ? nil : h
                    }(),
                    termLanguage: state.termLanguage,
                    translationLanguage: state.translationLanguage,
                    createdAt: state.createdAt,
                    updatedAt: Date(),
                    status: state.status
                )

                return .run { [term] send in
                    do {
                        try await persistenceClient.updateTerm(term)
                        await send(.saveCompleted)
                    } catch {
                        await send(.saveFailure(error.localizedDescription))
                    }
                }

            case .saveCompleted:
                state.isLoading = false
                state.isEditing = false
                return .send(.delegate(.termSaved))

            case .saveFailure:
                state.isLoading = false
                return .none

            case .deleteButtonTapped:
                let termText = state.termText
                state.alert = AlertState {
                    TextState("Видалити термін?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState("Видалити")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Скасувати")
                    }
                } message: {
                    TextState("Ви впевнені, що хочете видалити термін \"\(termText)\"?")
                }
                return .none

            case .alert(.presented(.confirmDelete)):
                let id = state.id
                state.isLoading = true
                return .run { [persistenceClient] send in
                    do {
                        try await persistenceClient.deleteTerm(id)
                        await send(.delegate(.termDeleted))
                    } catch {
                       
                    }
                }

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
