//
//  Exercise.swift
//  JohnsonApp
//

import Foundation

struct Exercise: Equatable, Identifiable, Sendable {
    let id: UUID
    let term: Term
    let type: ExerciseType
    let prompt: String
    let targetAnswer: String
    let options: [String]?
    
    init(
        id: UUID = UUID(),
        term: Term,
        type: ExerciseType,
        prompt: String,
        targetAnswer: String,
        options: [String]? = nil
    ) {
        self.id = id
        self.term = term
        self.type = type
        self.prompt = prompt
        self.targetAnswer = targetAnswer
        self.options = options
    }
}
