//
//  DictionaryFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation

@Reducer
struct DictionaryFeature {
    enum StatusFilter: String, CaseIterable, Identifiable, Equatable, Codable {
        case all = "Всі"
        case new = "Нові"
        case learning = "В процесі"
        case mastered = "Засвоєні"
        
        var id: String { self.rawValue }
    }
    
    @ObservableState
    struct State: Equatable {
        var terms: [Term] = []
        var searchQuery: String = ""
        var statusFilter: StatusFilter = .all
        var isLoading: Bool = false
        
        init(
            terms: [Term] = [],
            searchQuery: String = "",
            statusFilter: StatusFilter = .all,
            isLoading: Bool = false
        ) {
            self.terms = terms
            self.searchQuery = searchQuery
            self.statusFilter = statusFilter
            self.isLoading = isLoading
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case searchQueryChanged(String)
        case statusFilterChanged(StatusFilter)
        case fetchTerms
        case fetchTermsSuccess([Term])
        case fetchTermsFailure(String)
        case addButtonTapped
        case termTapped(Term)
    }
    
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.continuousClock) var clock
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    do {
                        let terms = try await persistenceClient.fetchTerms(nil)
                        if terms.isEmpty {
                            #if DEBUG
                            for term in Term.mockList {
                                try await persistenceClient.addTerm(term)
                            }
                            #endif
                        }
                    } catch {}
                    await send(.fetchTerms)
                }
                
            case let .searchQueryChanged(query):
                state.searchQuery = query
                state.isLoading = true
                return .run { send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.fetchTerms)
                }
                .cancellable(id: "search", cancelInFlight: true)
                
            case let .statusFilterChanged(filter):
                state.statusFilter = filter
                state.isLoading = true
                return .send(.fetchTerms)
                
            case .fetchTerms:
                let query = state.searchQuery
                return .run { send in
                    do {
                        let terms = try await persistenceClient.fetchTerms(query)
                        await send(.fetchTermsSuccess(terms))
                    } catch {
                        await send(.fetchTermsFailure(error.localizedDescription))
                    }
                }
                
            case let .fetchTermsSuccess(fetchedTerms):
                state.isLoading = false
                let filter = state.statusFilter
                state.terms = fetchedTerms.filter { term in
                    switch filter {
                    case .all:
                        return true
                    case .new:
                        return term.status == .new
                    case .learning:
                        return term.status == .learning
                    case .mastered:
                        return term.status == .mastered
                    }
                }
                return .none
                
            case .fetchTermsFailure:
                state.isLoading = false
                state.terms = []
                return .none
                
            case .addButtonTapped:
                return .none
                
            case .termTapped:
                return .none
            }
        }
    }
}
