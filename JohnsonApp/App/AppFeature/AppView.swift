//
//  AppView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    public var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            
            DictionaryView(store: store.scope(state: \.dictionary, action: \.dictionary))
            .tabItem {
                Label("Словник", systemImage: "character.book.closed")
            }
            .tag(AppFeature.Tab.dictionary)
            
            FlashcardView(store: store.scope(state: \.flashcard, action: \.flashcard))
            .tabItem {
                Label("Картки", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
            }
            .tag(AppFeature.Tab.flashcards)
           
            LearningSetupView(store: store.scope(state: \.learning, action: \.learning))
            .tabItem {
                Label("Навчання", systemImage: "graduationcap")
            }
            .tag(AppFeature.Tab.learning)
            
            NavigationStack {
                Text("Профіль")
                    .navigationTitle("Профіль")
            }
            .tabItem {
                Label("Профіль", systemImage: "person.crop.circle")
            }
            .tag(AppFeature.Tab.profile)
        }
    }
}


#Preview{
    AppView(
        store: Store(initialState: AppFeature.State()){
        AppFeature()
    }
    )
}
