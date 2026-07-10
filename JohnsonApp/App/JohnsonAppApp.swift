//
//  JohnsonAppApp.swift
//  JohnsonApp
//
//  Created by Діана Цісарук on 30.06.2026.
//

import SwiftUI
import ComposableArchitecture

@main
struct JohnsonAppApp: App {
    let store = Store(initialState: AppFeature.State()){
        AppFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
