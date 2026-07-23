//
//  LearningProgress.swift
//  JohnsonApp
//

import Foundation

struct LearningProgress: Equatable, Sendable {
    var stability: Double
    var difficulty: Double
    var dueDate: Date
    var lastReviewDate: Date?
    var repetitions: Int
    var lapses: Int

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

    var status: LearningStatus {
        guard lastReviewDate != nil else { return .new }
        return stability < 366 ? .learning : .mastered
    }
}
