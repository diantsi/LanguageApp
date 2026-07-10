//
//  SwiftDataContainer.swift
//  JohnsonApp
//

import Foundation
import SwiftData

@MainActor
class SwiftDataModelContainer {
    
    static var shared: ModelContainer = {
        let schema = Schema([
                Term.self,
                LearningProgress.self
            ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do{
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch{
            fatalError("could not create ModelContainer: \(error)")
        }
    }()
    
    
}
