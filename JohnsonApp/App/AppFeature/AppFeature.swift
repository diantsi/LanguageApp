//
//  AppFeature.swift
//  JohnsonApp
//
//  Created by Діана Цісарук on 10.07.2026.
//


import ComposableArchitecture
import Foundation

@Reducer
public struct AppFeature {
     
    public enum Tab: Equatable{
        case dictionary
        case flashcards
        case learning
        case profile
    }
    
    @ObservableState
    public struct State: Equatable{
        public var selectedTab: Tab = .dictionary
    }
    
    public enum Action: Equatable {
        case selectTab(Tab)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action{
            case let .selectTab(tab):
                state.selectedTab = tab
                return .none
            }
        }
    }
    
}
