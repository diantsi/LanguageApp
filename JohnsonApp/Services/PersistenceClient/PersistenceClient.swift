//
//  PersistenceClient.swift
//  JohnsonApp
//

import ComposableArchitecture
import Dependencies
import Foundation
import SwiftData

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

@ModelActor
actor DatabaseActor {
    func fetchTerms(query: String?, status: LearningStatus?, limit: Int?, offset: Int?) throws -> [Term] {
        let q = query ?? ""
        let hasQuery = !q.isEmpty

        let predicate = hasQuery ? #Predicate<Term> { term in
            term.termText.localizedStandardContains(q) || term.translation.localizedStandardContains(q)
        } : nil

        let descriptor = FetchDescriptor<Term>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        var terms = try modelContext.fetch(descriptor)
        
        if let status {
            terms = terms.filter { $0.status == status }
        }
        
        let start = offset ?? 0
        if start >= terms.count {
            return []
        }
        let end = limit != nil ? min(start + limit!, terms.count) : terms.count
        return Array(terms[start..<end])
    }

    func fetchTerm(id: UUID) throws -> Term? {
        let descriptor = FetchDescriptor<Term>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }

    func addTerm(_ term: Term) throws {
        modelContext.insert(term)
        try modelContext.save()
    }

    func addTerms(_ terms: [Term]) throws {
        for term in terms {
            modelContext.insert(term)
        }
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
        var descriptor = FetchDescriptor<LearningProgress>(
            predicate: #Predicate { $0.dueDate <= date },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        descriptor.fetchLimit = limit
        let progresses = try modelContext.fetch(descriptor)
        return progresses.compactMap { $0.term }
    }

    func termExists(termText: String, translation: String) throws -> Bool {
        let normalizedTerm = termText.trimmingCharacters(in: .whitespaces)
        let normalizedTranslation = translation.trimmingCharacters(in: .whitespaces)
        
        let descriptor = FetchDescriptor<Term>(
            predicate: #Predicate {
                $0.termText.localizedStandardContains(normalizedTerm) &&
                $0.translation.localizedStandardContains(normalizedTranslation)
            }
        )
        let candidates = try modelContext.fetch(descriptor)
        
        let lowercasedTerm = normalizedTerm.lowercased()
        let lowercasedTranslation = normalizedTranslation.lowercased()
        
        return candidates.contains { candidate in
            candidate.termText.trimmingCharacters(in: .whitespaces).lowercased() == lowercasedTerm &&
            candidate.translation.trimmingCharacters(in: .whitespaces).lowercased() == lowercasedTranslation
        }
    }
}

extension PersistenceClient: DependencyKey {
    static func live(modelContainer: ModelContainer) -> Self {
        let actor = DatabaseActor(modelContainer: modelContainer)
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

    static var liveValue: Self { live(modelContainer: SwiftDataModelContainer.shared) }

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
