//
//  PersistenceClient.swift
//  JohnsonApp
//

import ComposableArchitecture
import Dependencies
import Foundation
import GRDB


struct PersistenceClient {

    // MARK: - Session Operations
    var fetchSessions:  @Sendable () async throws -> [LanguageSession]
    var fetchSession:   @Sendable (UUID) async throws -> LanguageSession?
    var addSession:     @Sendable (LanguageSession) async throws -> Void
    var deleteSession:  @Sendable (UUID) async throws -> Void

    // MARK: - Term Operations (all scoped to a sessionId)
    var fetchTerms:          @Sendable (UUID, String?, LearningStatus?, Int?, Int?) async throws -> [Term]
    var fetchTerm:           @Sendable (UUID) async throws -> Term?
    var addTerm:             @Sendable (UUID, Term) async throws -> Void
    var addTerms:            @Sendable (UUID, [Term]) async throws -> Void
    var updateTerm:          @Sendable (Term) async throws -> Void
    var deleteTerm:          @Sendable (UUID) async throws -> Void
    var fetchDueTerms:       @Sendable (UUID, Date, Int) async throws -> [Term]
    var termExists:          @Sendable (UUID, String, String) async throws -> Bool
    var fetchSessionTermCounts: @Sendable () async throws -> [UUID: Int]

    // MARK: - Learning Progress Operations
    var fetchLearningProgress:  @Sendable (UUID) async throws -> LearningProgress?
    var updateLearningProgress: @Sendable (UUID, LearningProgress) async throws -> Void
}


extension PersistenceClient: DependencyKey {

    static func live(dbPool: any DatabaseWriter) -> Self {
        let actor = GRDBDatabaseActor(pool: dbPool)
        return Self(
            fetchSessions: {
                try await actor.fetchSessions()
            },
            fetchSession: { id in
                try await actor.fetchSession(id: id)
            },
            addSession: { session in
                try await actor.addSession(session)
            },
            deleteSession: { id in
                try await actor.deleteSession(id: id)
            },
            fetchTerms: { sessionId, query, status, limit, offset in
                try await actor.fetchTerms(sessionId: sessionId, query: query, status: status, limit: limit, offset: offset)
            },
            fetchTerm: { id in
                try await actor.fetchTerm(id: id)
            },
            addTerm: { sessionId, term in
                try await actor.addTerm(sessionId: sessionId, term)
            },
            addTerms: { sessionId, terms in
                try await actor.addTerms(sessionId: sessionId, terms)
            },
            updateTerm: { term in
                try await actor.updateTerm(term)
            },
            deleteTerm: { id in
                try await actor.deleteTerm(id: id)
            },
            fetchDueTerms: { sessionId, date, limit in
                try await actor.fetchDueTerms(sessionId: sessionId, date: date, limit: limit)
            },
            termExists: { sessionId, termText, translation in
                try await actor.termExists(sessionId: sessionId, termText: termText, translation: translation)
            },
            fetchSessionTermCounts: {
                try await actor.fetchSessionTermCounts()
            },
            fetchLearningProgress: { id in
                try await actor.fetchLearningProgress(termId: id)
            },
            updateLearningProgress: { id, progress in
                try await actor.updateLearningProgress(termId: id, progress: progress)
            }
        )
    }

    static var liveValue: Self { live(dbPool: AppDatabase.shared) }


    static let testValue = Self(
        fetchSessions:          { [] },
        fetchSession:           { _ in nil },
        addSession:             { _ in },
        deleteSession:          { _ in },
        fetchTerms:             { _, _, _, _, _ in [] },
        fetchTerm:              { _ in nil },
        addTerm:                { _, _ in },
        addTerms:               { _, _ in },
        updateTerm:             { _ in },
        deleteTerm:             { _ in },
        fetchDueTerms:          { _, _, _ in [] },
        termExists:             { _, _, _ in false },
        fetchSessionTermCounts: { [:] },
        fetchLearningProgress:  { _ in nil },
        updateLearningProgress: { _, _ in }
    )


    static let previewValue: Self = {
        let mockSession = LanguageSession.mock
        let mockTerms = Term.mockList
        return Self(
            fetchSessions: { [mockSession] },
            fetchSession:  { _ in mockSession },
            addSession: { _ in },
            deleteSession: { _ in },
            fetchTerms: { _, query, status, limit, offset in
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
            addTerm: { _, _ in },
            addTerms: { _, _ in },
            updateTerm: { _ in },
            deleteTerm: { _ in },
            fetchDueTerms: { _, _, _ in mockTerms },
            termExists: { _, termText, translation in
                let normalizedTerm = termText.trimmingCharacters(in: .whitespaces).lowercased()
                let normalizedTranslation = translation.trimmingCharacters(in: .whitespaces).lowercased()
                return mockTerms.contains {
                    $0.termText.trimmingCharacters(in: .whitespaces).lowercased() == normalizedTerm &&
                    $0.translation.trimmingCharacters(in: .whitespaces).lowercased() == normalizedTranslation
                }
            },
            fetchSessionTermCounts: { [mockSession.id: mockTerms.count] },
            fetchLearningProgress: { _ in LearningProgress(dueDate: Date()) },
            updateLearningProgress: { _, _ in }
        )
    }()
}


extension DependencyValues {
    var persistenceClient: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
