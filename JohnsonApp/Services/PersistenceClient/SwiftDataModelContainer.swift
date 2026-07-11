//
//  SwiftDataModelContainer.swift
//  JohnsonApp
//

import Foundation
import SwiftData

class SwiftDataModelContainer {
    private init() {}
    
    static let shared: ModelContainer = {
        let schema = Schema([
            Term.self,
            LearningProgress.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    
}
