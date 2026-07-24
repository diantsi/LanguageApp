//
//  Language.swift
//  JohnsonApp
//

import Foundation

enum Language: String, Codable, CaseIterable {
    case english
    case ukrainian

    var bcp47: String {
        switch self {
        case .english:    return "en-US"
        case .ukrainian:  return "uk-UA"
        }
    }
}
