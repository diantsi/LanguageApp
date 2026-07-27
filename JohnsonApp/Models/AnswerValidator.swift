//
//  AnswerValidator.swift
//  JohnsonApp
//

import Foundation

enum ValidationResult: Equatable {
    case correct
    case typo(distance: Int)
    case incorrect
}

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
    
    /// Calculates Levenshtein edit distance between two strings
    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let empty = Array(repeating: 0, count: s2.count + 1)
        var matrix = Array(repeating: empty, count: s1.count + 1)

        for i in 0...s1.count { matrix[i][0] = i }
        for j in 0...s2.count { matrix[0][j] = j }

        let a1 = Array(s1)
        let a2 = Array(s2)

        if s1.isEmpty || s2.isEmpty {
            return max(s1.count, s2.count)
        }

        for i in 1...s1.count {
            for j in 1...s2.count {
                if a1[i - 1] == a2[j - 1] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1,      // deletion
                        matrix[i][j - 1] + 1,      // insertion
                        matrix[i - 1][j - 1] + 1   // substitution
                    )
                }
            }
        }
        return matrix[s1.count][s2.count]
    }

    /// Validates user answer with Typo Detection
    static func validateResult(userAnswer: String, targetAnswer: String) -> ValidationResult {
        let normUser = normalize(userAnswer)
        let normTarget = normalize(targetAnswer)

        if normUser == normTarget {
            return .correct
        }

        let distance = levenshteinDistance(normUser, normTarget)

        if distance == 1 && normTarget.count >= 4 {
            return .typo(distance: distance)
        }

        return .incorrect
    }
    
    static func validate(userAnswer: String, targetAnswer: String) -> Bool {
        return validateResult(userAnswer: userAnswer, targetAnswer: targetAnswer) == .correct
    }
}
