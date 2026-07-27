//
//  AnswerValidator.swift
//  JohnsonApp
//

import Foundation

struct AnswerValidator {
    /// Normalizes text according to business rules:
    /// 1. Trim leading/trailing spaces and newlines
    /// 2. Replace multiple consecutive spaces with a single space
    /// 3. Lowercase
    /// 4. Trim trailing punctuation (".", ",", "!", "?")
    static func normalize(_ string: String) -> String {
        var result = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        
        result = result.lowercased()
        
        let punctuation: Set<Character> = [".", ",", "!", "?"]
        while let last = result.last, punctuation.contains(last) {
            result.removeLast()
        }
        
        return result
    }
    
    static func validate(userAnswer: String, targetAnswer: String) -> Bool {
        return normalize(userAnswer) == normalize(targetAnswer)
    }
}
