//
//  Term.swift
//  JohnsonApp
//

import Foundation

struct Term: Equatable, Identifiable, Sendable {
    let id: UUID
    let termText: String
    let translation: String
    let hint: String?
    let termLanguage: Language
    let translationLanguage: Language
    let createdAt: Date
    let updatedAt: Date
    let status: LearningStatus

    nonisolated init(
        id: UUID = UUID(),
        termText: String,
        translation: String,
        hint: String? = nil,
        termLanguage: Language = .english,
        translationLanguage: Language = .ukrainian,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        status: LearningStatus = .new
    ) {
        self.id = id
        self.termText = termText
        self.translation = translation
        self.hint = hint
        self.termLanguage = termLanguage
        self.translationLanguage = translationLanguage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
    }
}

extension Term {
    static var mockList: [Term] {
        [
            Term(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                termText: "apple",
                translation: "яблуко",
                hint: "не бренд",
                termLanguage: .english,
                translationLanguage: .ukrainian,
                createdAt: Date(timeIntervalSince1970: 1_000_000),
                updatedAt: Date(timeIntervalSince1970: 1_000_000),
                status: .new
            ),
            Term(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                termText: "cacao",
                translation: "какао",
                hint: "кококо",
                termLanguage: .english,
                translationLanguage: .ukrainian,
                createdAt: Date(timeIntervalSince1970: 1_000_001),
                updatedAt: Date(timeIntervalSince1970: 1_000_001),
                status: .new
            ),
        ]
    }
}
