//
//  LearningStatus.swift
//  JohnsonApp
//

import Foundation

public enum LearningStatus: String, CaseIterable, Identifiable, Codable {
    case new
    case learning
    case mastered
    
    public var id: String { self.rawValue }
    
    public var localizedName: String {
        switch self {
        case .new:
            return "Нове"
        case .learning:
            return "Вчу"
        case .mastered:
            return "Засвоєно"
        }
    }
}
