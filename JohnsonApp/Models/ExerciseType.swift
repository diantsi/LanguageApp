//
//  ExerciseType.swift
//  JohnsonApp
//

import Foundation

enum ExerciseType: String, Codable, CaseIterable {
    case multipleChoice
    case writeTerm
    case writeTranslation
    case listening
}
