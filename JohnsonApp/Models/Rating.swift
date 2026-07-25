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
    
}
