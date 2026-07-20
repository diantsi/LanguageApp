//
//  DictionaryFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation

@Reducer
struct DictionaryFeature {
    enum StatusFilter: CaseIterable, Identifiable, Equatable {
        case all
        case new
        case learning
        case mastered
        var id: Self { self }
        var title: String {
            switch self {
            case .all: return "Всі"
            case .new: return "Нові"
            case .learning: return "В процесі"
            case .mastered: return "Засвоєні"
            }
        }
        var learningStatus: LearningStatus? {
            switch self {
            case .all: return nil
            case .new: return .new
            case .learning: return .learning
            case .mastered: return .mastered
            }
        }
    }

    @ObservableState
    struct State: Equatable {
        var terms: [Term] = []
        var searchQuery: String = ""
        var statusFilter: StatusFilter = .all
        var isLoading: Bool = false
        var hasMore: Bool = true
        @Presents var addTerms: AddTermsFeature.State?
        @Presents var editTerm: EditTermFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        init(
            terms: [Term] = [],
            searchQuery: String = "",
            statusFilter: StatusFilter = .all,
            isLoading: Bool = false,
            hasMore: Bool = true,
            addTerms: AddTermsFeature.State? = nil,
            editTerm: EditTermFeature.State? = nil,
            alert: AlertState<Action.Alert>? = nil
        ) {
            self.terms = terms
            self.searchQuery = searchQuery
            self.statusFilter = statusFilter
            self.isLoading = isLoading
            self.hasMore = hasMore
            self.addTerms = addTerms
            self.editTerm = editTerm
            self.alert = alert
        }
    }

    enum Action: Equatable {
        case onAppear
        case searchQueryChanged(String)
        case statusFilterChanged(StatusFilter)
        case fetchTerms
        case fetchTermsSuccess([Term], isLoadMore: Bool)
        case fetchTermsFailure(String)
        case loadMoreTerms
        case addButtonTapped
        case termTapped(Term)
        case addTerms(PresentationAction<AddTermsFeature.Action>)
        case editTerm(PresentationAction<EditTermFeature.Action>)
        case deleteButtonTapped(Term)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {
            case confirmDelete(Term)
        }
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.continuousClock) var clock

    private let pageSize = 40

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.terms.isEmpty else { return .none }
                state.isLoading = true
                return .send(.fetchTerms)

            case let .searchQueryChanged(query):
                state.searchQuery = query
                state.isLoading = true
                state.hasMore = true
                return .run { send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.fetchTerms)
                }
                .cancellable(id: "search", cancelInFlight: true)

            case let .statusFilterChanged(filter):
                state.statusFilter = filter
                state.isLoading = true
                state.terms = []
                state.hasMore = true
                return .send(.fetchTerms)
            case .fetchTerms:
                let query = state.searchQuery
                let status = state.statusFilter.learningStatus
                let limit = pageSize
                return .run { send in
                    do {
                        let terms = try await persistenceClient.fetchTerms(query, status, limit, 0)
                        await send(.fetchTermsSuccess(terms, isLoadMore: false))
                    } catch {
                        await send(.fetchTermsFailure(error.localizedDescription))
                    }
                }

            case .loadMoreTerms:
                guard !state.isLoading, state.hasMore else { return .none }
                state.isLoading = true
                let query = state.searchQuery
                let status = state.statusFilter.learningStatus
                let limit = pageSize
                let offset = state.terms.count
                return .run { send in
                    do {
                        let terms = try await persistenceClient.fetchTerms(query, status, limit, offset)
                        await send(.fetchTermsSuccess(terms, isLoadMore: true))
                    } catch {
                        await send(.fetchTermsFailure(error.localizedDescription))
                    }
                }

            case let .fetchTermsSuccess(fetchedTerms, isLoadMore):
                state.isLoading = false
                if isLoadMore {
                    state.terms.append(contentsOf: fetchedTerms)
                } else {
                    state.terms = fetchedTerms
                }
                state.hasMore = fetchedTerms.count >= pageSize
                return .none

            case .fetchTermsFailure:
                state.isLoading = false
                state.hasMore = false
                return .none

            case .addButtonTapped:
                state.addTerms = AddTermsFeature.State()
                return .none

            case let .termTapped(term):
                state.editTerm = EditTermFeature.State(term: term)
                return .none

            case .editTerm(.presented(.delegate(.termSaved))):
                state.terms = []
                state.hasMore = true
                return .send(.fetchTerms)

            case .editTerm(.presented(.delegate(.termDeleted))):
                state.editTerm = nil
                state.terms = []
                state.hasMore = true
                return .send(.fetchTerms)

            case .editTerm:
                return .none

            case .addTerms(.presented(.delegate(.termsSaved))):
                state.addTerms = nil
                state.terms = []
                state.hasMore = true
                return .send(.fetchTerms)

            case .addTerms:
                return .none

            case let .deleteButtonTapped(term):
                state.alert = AlertState {
                    TextState("Видалити термін?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(term)) {
                        TextState("Видалити")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Скасувати")
                    }
                } message: {
                    TextState("Ви впевнені, що хочете видалити термін \"\(term.termText)\"?")
                }
                return .none

            case let .alert(.presented(.confirmDelete(term))):
                let id = term.id
                state.isLoading = true
                return .run { [persistenceClient] send in
                    do {
                        try await persistenceClient.deleteTerm(id)
                        await send(.fetchTerms)
                    } catch {
                        await send(.fetchTermsFailure(error.localizedDescription))
                    }
                }

            case .alert:
                return .none
            }
        }
        .ifLet(\.$addTerms, action: \.addTerms) {
            AddTermsFeature()
        }
        .ifLet(\.$editTerm, action: \.editTerm) {
            EditTermFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
