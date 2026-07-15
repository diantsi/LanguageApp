//
//  ImportModels.swift
//  JohnsonApp
//

import Foundation

struct ParsedTerm: Identifiable {
    let id: UUID
    var termText: String
    var translation: String
    var hint: String?

    nonisolated init(id: UUID = UUID(), termText: String, translation: String, hint: String? = nil) {
        self.id = id
        self.termText = termText
        self.translation = translation
        self.hint = hint
    }
}

extension ParsedTerm: Equatable {
    static func == (lhs: ParsedTerm, rhs: ParsedTerm) -> Bool {
        lhs.termText == rhs.termText &&
        lhs.translation == rhs.translation &&
        lhs.hint == rhs.hint
    }
}

struct InvalidLine: Equatable {
    var lineNumber: Int
    var content: String
}

struct ImportResult: Equatable {
    var validTerms: [ParsedTerm]
    var invalidLines: [InvalidLine]
}
