//
//  Term.swift
//  JohnsonApp
//

import SwiftUI
import SwiftData


@Model
class Term {
    var id: UUID
    var termText: String
    var translation: String
    var hint: String?
    var termLanguage: Language
    var translationLanguage: Language
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade)
    var learningProgress: LearningProgress?
    
    init(
        id: UUID = UUID(),
        termText: String,
        translation: String,
        hint: String? = nil,
        termLanguage: Language,
        translationLanguage: Language,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.termText = termText
        self.translation = translation
        self.hint = hint
        self.termLanguage = termLanguage
        self.translationLanguage = translationLanguage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.learningProgress = LearningProgress(dueDate: createdAt)
    }
    
}
