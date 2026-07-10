//
//  LearningProgress.swift
//  JohnsonApp
//

import Foundation
import SwiftData

@Model
class LearningProgress {
    var stability: Double
    var difficulty: Double
    var dueDate: Date
    var lastReviewDate: Date?
    var repetitions: Int
    var lapses: Int
    
    @Relationship(inverse: \Term.learningProgress)
    var term: Term?
    
    init(
        stability: Double = 0.0,
        difficulty: Double = 0.0,
        dueDate: Date,
        lastReviewDate: Date? = nil,
        repetitions: Int = 0,
        lapses: Int = 0
    ) {
        self.stability = stability
        self.difficulty = difficulty
        self.dueDate = dueDate
        self.lastReviewDate = lastReviewDate
        self.repetitions = repetitions
        self.lapses = lapses
    }
}
