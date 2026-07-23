//
//  PersistenceClient.swift
//  JohnsonApp
//

import ComposableArchitecture
import Dependencies
import Foundation
import GRDB


struct PersistenceClient {
    var fetchTerms: @Sendable (String?, LearningStatus?, Int?, Int?) async throws -> [Term]
    var fetchTerm: @Sendable (UUID) async throws -> Term?
    var addTerm: @Sendable (Term) async throws -> Void
    var addTerms: @Sendable ([Term]) async throws -> Void
    var updateTerm: @Sendable (Term) async throws -> Void
    var deleteTerm: @Sendable (UUID) async throws -> Void
    var fetchDueTerms: @Sendable (Date, Int) async throws -> [Term]
    var termExists: @Sendable (String, String) async throws -> Bool
}


extension PersistenceClient: DependencyKey {

    static func live(dbPool: any DatabaseWriter) -> Self {
        let actor = GRDBDatabaseActor(pool: dbPool)
        return Self(
            fetchTerms: { query, status, limit, offset in
                try await actor.fetchTerms(query: query, status: status, limit: limit, offset: offset)
            },
            fetchTerm: { id in
                try await actor.fetchTerm(id: id)
            },
            addTerm: { term in
                try await actor.addTerm(term)
            },
            addTerms: { terms in
                try await actor.addTerms(terms)
            },
            updateTerm: { term in
                try await actor.updateTerm(term)
            },
            deleteTerm: { id in
                try await actor.deleteTerm(id: id)
            },
            fetchDueTerms: { date, limit in
                try await actor.fetchDueTerms(date: date, limit: limit)
            },
            termExists: { termText, translation in
                try await actor.termExists(termText: termText, translation: translation)
            }
        )
    }

    static var liveValue: Self { live(dbPool: AppDatabase.shared) }


    static let testValue = Self(
        fetchTerms: { _, _, _, _ in [] },
        fetchTerm: { _ in nil },
        addTerm: { _ in },
        addTerms: { _ in },
        updateTerm: { _ in },
        deleteTerm: { _ in },
        fetchDueTerms: { _, _ in [] },
        termExists: { _, _ in false }
    )


    static let previewValue: Self = {
        let mockTerms = Term.mockList
        return Self(
            fetchTerms: { query, status, limit, offset in
                var result = mockTerms
                if let query, !query.isEmpty {
                    result = result.filter {
                        $0.termText.localizedStandardContains(query) ||
                        $0.translation.localizedStandardContains(query)
                    }
                }
                if let status {
                    result = result.filter { $0.status == status }
                }
                let start = offset ?? 0
                if start >= result.count { return [] }
                let end = limit != nil ? min(start + limit!, result.count) : result.count
                return Array(result[start..<end])
            },
            fetchTerm: { id in mockTerms.first(where: { $0.id == id }) },
            addTerm: { _ in },
            addTerms: { _ in },
            updateTerm: { _ in },
            deleteTerm: { _ in },
            fetchDueTerms: { _, _ in [] },
            termExists: { termText, translation in
                let normalizedTerm = termText.trimmingCharacters(in: .whitespaces).lowercased()
                let normalizedTranslation = translation.trimmingCharacters(in: .whitespaces).lowercased()
                return mockTerms.contains {
                    $0.termText.trimmingCharacters(in: .whitespaces).lowercased() == normalizedTerm &&
                    $0.translation.trimmingCharacters(in: .whitespaces).lowercased() == normalizedTranslation
                }
            }
        )
    }()
}


extension DependencyValues {
    var persistenceClient: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
