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
        var flashcard = FlashcardFeature.State()
        var learning = LearningSetupFeature.State()
    }
    
    enum Action: Equatable {
        case selectTab(Tab)
        case dictionary(DictionaryFeature.Action)
        case flashcard(FlashcardFeature.Action)
        case learning(LearningSetupFeature.Action)
    }
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.dictionary, action: \.dictionary) {
            DictionaryFeature()
        }
        Scope(state: \.flashcard, action: \.flashcard) {
            FlashcardFeature()
        }
        Scope(state: \.learning, action: \.learning) {
            LearningSetupFeature()
        }

        Reduce{ state, action in
            switch action{
            case let .selectTab(tab):
                state.selectedTab = tab
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
            }
        }
    }
    
}
