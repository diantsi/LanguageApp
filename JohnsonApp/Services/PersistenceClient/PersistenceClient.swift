//
//  PersistenceClient.swift
//  JohnsonApp
//

import ComposableArchitecture
import Dependencies
import Foundation
import SwiftData

struct PersistenceClient {
    var fetchTerms: @Sendable (String?) async throws -> [Term]
    var fetchTerm: @Sendable (UUID) async throws -> Term?
    var addTerm: @Sendable (Term) async throws -> Void
    var updateTerm: @Sendable (Term) async throws -> Void
    var deleteTerm: @Sendable (UUID) async throws -> Void
    var fetchDueTerms: @Sendable (Date, Int) async throws -> [Term]
}

@ModelActor
actor DatabaseActor {
    func fetchTerms(query: String?) throws -> [Term] {
        let descriptor: FetchDescriptor<Term>
        
        if let query = query, !query.isEmpty {
            descriptor = FetchDescriptor<Term>(
                predicate: #Predicate {
                    $0.termText.localizedStandardContains(query) ||
                    $0.translation.localizedStandardContains(query)
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<Term>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    func fetchTerm(id: UUID) throws -> Term? {
        let descriptor = FetchDescriptor<Term>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }
    
    func addTerm(_ term: Term) throws {
        modelContext.insert(term)
        try modelContext.save()
    }
    
    func updateTerm(_ term: Term) throws {
        if let localTerm = try fetchTerm(id: term.id) {
            localTerm.termText = term.termText
            localTerm.translation = term.translation
            localTerm.hint = term.hint
            localTerm.termLanguage = term.termLanguage
            localTerm.translationLanguage = term.translationLanguage
            localTerm.updatedAt = Date()
            try modelContext.save()
        }
    }
    
    func deleteTerm(id: UUID) throws {
        let descriptor = FetchDescriptor<Term>(predicate: #Predicate { $0.id == id })
        if let term = try modelContext.fetch(descriptor).first {
            modelContext.delete(term)
            try modelContext.save()
        }
    }
    
    func fetchDueTerms(date: Date, limit: Int) throws -> [Term] {
        let descriptor = FetchDescriptor<Term>()
        let terms = try modelContext.fetch(descriptor)
        return Array(terms.filter { term in
            guard let progress = term.learningProgress else { return false }
            return progress.dueDate <= date
        }.prefix(limit))
    }
}

extension PersistenceClient: DependencyKey {
    static var liveValue: Self {
        let actor = DatabaseActor(modelContainer: SwiftDataModelContainer.shared)
        return Self(
            fetchTerms: { query in
                try await actor.fetchTerms(query: query)
            },
            fetchTerm: { id in
                try await actor.fetchTerm(id: id)
            },
            addTerm: { term in
                try await actor.addTerm(term)
            },
            updateTerm: { term in
                try await actor.updateTerm(term)
            },
            deleteTerm: { id in
                try await actor.deleteTerm(id: id)
            },
            fetchDueTerms: { date, limit in
                try await actor.fetchDueTerms(date: date, limit: limit)
            }
        )
    }
    
    static let testValue = Self(
        fetchTerms: { _ in [] },
        fetchTerm: { _ in nil },
        addTerm: { _ in },
        updateTerm: { _ in },
        deleteTerm: { _ in },
        fetchDueTerms: { _, _ in [] }
    )
    
    
    static let previewValue: Self = {
        let mockTerms = Term.mockList
        return Self(
            fetchTerms: { query in
                if let query = query, !query.isEmpty {
                    return mockTerms.filter {
                        $0.termText.localizedStandardContains(query) ||
                        $0.translation.localizedStandardContains(query)
                    }
                }
                return mockTerms
            },
            fetchTerm: { id in mockTerms.first(where: { $0.id == id }) },
            addTerm: { _ in },
            updateTerm: { _ in },
            deleteTerm: { _ in },
            fetchDueTerms: { _, _ in [] }
        )
    }()
}

extension DependencyValues {
    var persistenceClient: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
