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

    var title: String {
        switch self {
        case .multipleChoice: return "Множинний вибір"
        case .writeTerm: return "Написати термін"
        case .writeTranslation: return "Написати переклад"
        case .listening: return "Аудіювання"
        }
    }
}
