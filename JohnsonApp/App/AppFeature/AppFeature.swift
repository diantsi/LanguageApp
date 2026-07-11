//
//  AppFeature.swift
//  JohnsonApp
//


import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
     
    enum Tab: Equatable{
        case dictionary
        case flashcards
        case learning
        case profile
    }
    
    @ObservableState
    struct State: Equatable{
        var selectedTab: Tab = .dictionary
        var dictionary = DictionaryFeature.State()
    }
    
    enum Action: Equatable {
        case selectTab(Tab)
        case dictionary(DictionaryFeature.Action)
    }
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.dictionary, action: \.dictionary) {
            DictionaryFeature()
        }
        
        Reduce{ state, action in
            switch action{
            case let .selectTab(tab):
                state.selectedTab = tab
                return .none
            case .dictionary:
                return .none
            }
        }
    }
    
}

