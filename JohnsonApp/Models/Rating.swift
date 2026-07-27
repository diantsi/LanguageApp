//
//  Rating.swift
//  JohnsonApp
//

import Foundation

enum Rating: Int, CaseIterable, Identifiable, Codable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    var id: Int { self.rawValue }

    /// Calculates FSRS Rating based on exercise performance
    static func calculate(correctCount: Int, totalExercises: Int) -> Rating {
        if totalExercises >= 4 {
            switch correctCount {
            case 0...1: return .again
            case 2:     return .hard
            case 3:     return .good
            default:    return .easy
            }
        } else {
            switch correctCount {
            case 0:  return .again
            case 1:  return .hard
            case 2:  return .good
            default: return .easy
            }
        }
    }
}
