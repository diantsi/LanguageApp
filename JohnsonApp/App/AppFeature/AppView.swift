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
                Label("Dictionary", systemImage: "character.book.closed")
            }
            .tag(AppFeature.Tab.dictionary)
            
            NavigationStack {
                Text("Flashcards Placeholder")
                    .navigationTitle("Flashcards")
            }
            .tabItem {
                Label("Flashcards", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
            }
            .tag(AppFeature.Tab.flashcards)
            
            NavigationStack {
                Text("Learning Placeholder")
                    .navigationTitle("Learning")
            }
            .tabItem {
                Label("Learning", systemImage: "graduationcap")
            }
            .tag(AppFeature.Tab.learning)
            
            NavigationStack {
                Text("Profile Placeholder")
                    .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
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
