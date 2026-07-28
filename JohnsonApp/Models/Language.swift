//
//  Language.swift
//  JohnsonApp
//

import Foundation

enum Language: String, Codable, CaseIterable {
    case english
    case ukrainian
    case french
    case polish

    var bcp47: String {
        switch self {
        case .english:    return "en-US"
        case .ukrainian:  return "uk-UA"
        case .french:     return "fr-FR"
        case .polish:     return "pl-PL"
        }
    }

    var displayName: String {
        switch self {
        case .english:    return "Англійська"
        case .ukrainian:  return "Українська"
        case .french:     return "Французька"
        case .polish:     return "Польська"
        }
    }
}
