//
//  LanguageSession.swift
//  JohnsonApp
//

import Foundation

struct LanguageSession: Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    let termLanguage: Language
    let translationLanguage: Language
    let createdAt: Date
}

extension LanguageSession {
    static var mock: LanguageSession {
        LanguageSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "English → Ukrainian",
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: Date(timeIntervalSince1970: 1_000_000)
        )
    }
}
