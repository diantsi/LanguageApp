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
    
    var status: LearningStatus {
        guard let progress = learningProgress else { return .new }
        if progress.lastReviewDate == nil {
            return .new
        } else if progress.stability < 366 {
            return .learning
        } else {
            return .mastered
        }
    }
}

extension Term: Equatable {
    static func == (lhs: Term, rhs: Term) -> Bool {
        lhs.id == rhs.id &&
        lhs.termText == rhs.termText &&
        lhs.translation == rhs.translation &&
        lhs.hint == rhs.hint &&
        lhs.termLanguage == rhs.termLanguage &&
        lhs.translationLanguage == rhs.translationLanguage &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt
    }

    static var mockList: [Term] {
        let term1 = Term(
            termText: "apple",
            translation: "яблуко",
            hint: "не бренд",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )
        
        let term2 = Term(
            termText: "cacao",
            translation: "какао",
            hint: "кококо",
            termLanguage: .english,
            translationLanguage: .ukrainian
        )

        return [term1, term2]
    }
}
