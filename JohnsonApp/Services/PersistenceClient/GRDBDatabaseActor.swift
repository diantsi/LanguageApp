//
//  GRDBDatabaseActor.swift
//  JohnsonApp
//

import Foundation
import GRDB

actor GRDBDatabaseActor {

    private let pool: any DatabaseWriter

    init(pool: any DatabaseWriter) {
        self.pool = pool
    }


    private struct TermRow: Codable, FetchableRecord, PersistableRecord, Sendable {
        static let databaseTableName = "terms"
        var id: String
        var termText: String
        var translation: String
        var hint: String?
        var termLanguage: String
        var translationLanguage: String
        var createdAt: Double
        var updatedAt: Double

        init(term: Term) {
            self.id = term.id.uuidString
            self.termText = term.termText
            self.translation = term.translation
            self.hint = term.hint
            self.termLanguage = term.termLanguage.rawValue
            self.translationLanguage = term.translationLanguage.rawValue
            self.createdAt = term.createdAt.timeIntervalSince1970
            self.updatedAt = term.updatedAt.timeIntervalSince1970
        }
    }

    private struct LearningProgressRow: Codable, FetchableRecord, PersistableRecord, Sendable {
        static let databaseTableName = "learning_progress"
        var termId: String
        var stability: Double
        var difficulty: Double
        var dueDate: Double
        var lastReviewDate: Double?
        var repetitions: Int
        var lapses: Int

        init(termId: String, dueDate: Date = Date()) {
            self.termId = termId
            self.stability = 0.0
            self.difficulty = 0.0
            self.dueDate = dueDate.timeIntervalSince1970
            self.lastReviewDate = nil
            self.repetitions = 0
            self.lapses = 0
        }

        init(termId: UUID, progress: LearningProgress) {
            self.termId = termId.uuidString
            self.stability = progress.stability
            self.difficulty = progress.difficulty
            self.dueDate = progress.dueDate.timeIntervalSince1970
            self.lastReviewDate = progress.lastReviewDate?.timeIntervalSince1970
            self.repetitions = progress.repetitions
            self.lapses = progress.lapses
        }

        func toLearningProgress() -> LearningProgress {
            LearningProgress(
                stability: stability,
                difficulty: difficulty,
                dueDate: Date(timeIntervalSince1970: dueDate),
                lastReviewDate: lastReviewDate.map { Date(timeIntervalSince1970: $0) },
                repetitions: repetitions,
                lapses: lapses
            )
        }
    }

    private struct TermWithStatusRow: FetchableRecord, Sendable {
        let id: String
        let termText: String
        let translation: String
        let hint: String?
        let termLanguage: String
        let translationLanguage: String
        let createdAt: Double
        let updatedAt: Double
        let status: String

        init(row: Row) {
            id = row["id"]
            termText = row["termText"]
            translation = row["translation"]
            hint = row["hint"]
            termLanguage = row["termLanguage"]
            translationLanguage = row["translationLanguage"]
            createdAt = row["createdAt"]
            updatedAt = row["updatedAt"]
            status = row["status"] ?? "new"
        }

        func toTerm() -> Term? {
            guard
                let uuid = UUID(uuidString: id),
                let lang = Language(rawValue: termLanguage),
                let transLang = Language(rawValue: translationLanguage),
                let learningStatus = LearningStatus(rawValue: status)
            else { return nil }

            return Term(
                id: uuid,
                termText: termText,
                translation: translation,
                hint: hint,
                termLanguage: lang,
                translationLanguage: transLang,
                createdAt: Date(timeIntervalSince1970: createdAt),
                updatedAt: Date(timeIntervalSince1970: updatedAt),
                status: learningStatus
            )
        }
    }

    private static let statusCaseSQL = """
        CASE
          WHEN lp.termId IS NULL OR lp.lastReviewDate IS NULL THEN 'new'
          WHEN lp.stability < 366.0                           THEN 'learning'
          ELSE                                                     'mastered'
        END AS status
        """

    private static let termJoinSQL = """
        SELECT
          t.id, t.termText, t.translation, t.hint,
          t.termLanguage, t.translationLanguage,
          t.createdAt, t.updatedAt,
          \(statusCaseSQL)
        FROM terms t
        LEFT JOIN learning_progress lp ON lp.termId = t.id
        """


    func fetchTerms(
        query: String?,
        status: LearningStatus?,
        limit: Int?,
        offset: Int?
    ) throws -> [Term] {
        try pool.read { db in
            let hasQuery = query.map { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? false
            let hasStatus = status != nil

            var sql = """
                WITH enriched AS (
                  \(Self.termJoinSQL)
                  WHERE \(hasQuery ? "(t.termText LIKE ? OR t.translation LIKE ?)" : "1=1")
                )
                SELECT * FROM enriched
                WHERE \(hasStatus ? "status = ?" : "1=1")
                ORDER BY createdAt DESC
                """

            var arguments: [DatabaseValue] = []

            if hasQuery, let q = query {
                let pattern = "%\(q)%"
                arguments += [pattern.databaseValue, pattern.databaseValue]
            }

            if let status {
                arguments.append(status.rawValue.databaseValue)
            }

            if let limit {
                sql += "\nLIMIT ?"
                arguments.append(limit.databaseValue)
                if let offset {
                    sql += "\nOFFSET ?"
                    arguments.append(offset.databaseValue)
                }
            } else if let offset {
                sql += "\nLIMIT -1 OFFSET ?"
                arguments.append(offset.databaseValue)
            }

            return try TermWithStatusRow
                .fetchAll(db, sql: sql, arguments: StatementArguments(arguments))
                .compactMap { $0.toTerm() }
        }
    }

    func fetchTerm(id: UUID) throws -> Term? {
        try pool.read { db in
            let sql = "\(Self.termJoinSQL)\nWHERE t.id = ?"
            return try TermWithStatusRow
                .fetchOne(db, sql: sql, arguments: [id.uuidString])
                .flatMap { $0.toTerm() }
        }
    }

    func addTerm(_ term: Term) throws {
        try pool.write { db in
            try TermRow(term: term).insert(db)
            try LearningProgressRow(termId: term.id.uuidString, dueDate: term.createdAt).insert(db)
        }
    }

    func addTerms(_ terms: [Term]) throws {
        try pool.write { db in
            for term in terms {
                try TermRow(term: term).insert(db)
                try LearningProgressRow(termId: term.id.uuidString, dueDate: term.createdAt).insert(db)
            }
        }
    }

    func updateTerm(_ term: Term) throws {
        try pool.write { db in
            try TermRow(term: term).update(db)
        }
    }

    func deleteTerm(id: UUID) throws {
        try pool.write { db in
            _ = try TermRow.deleteOne(db, key: id.uuidString)
        }
    }

    func fetchDueTerms(date: Date, limit: Int) throws -> [Term] {
        try pool.read { db in
            let sql = """
                SELECT
                  t.id, t.termText, t.translation, t.hint,
                  t.termLanguage, t.translationLanguage,
                  t.createdAt, t.updatedAt,
                  \(Self.statusCaseSQL)
                FROM learning_progress lp
                INNER JOIN terms t ON t.id = lp.termId
                WHERE lp.dueDate <= ?
                ORDER BY lp.dueDate ASC
                LIMIT ?
                """
            return try TermWithStatusRow
                .fetchAll(db, sql: sql, arguments: [date.timeIntervalSince1970, limit])
                .compactMap { $0.toTerm() }
        }
    }

    func termExists(termText: String, translation: String) throws -> Bool {
        try pool.read { db in
            let row = try Row.fetchOne(
                db,
                sql: """
                    SELECT 1 FROM terms
                    WHERE TRIM(termText) COLLATE swift_nocase = TRIM(?) COLLATE swift_nocase
                      AND TRIM(translation) COLLATE swift_nocase = TRIM(?) COLLATE swift_nocase
                    LIMIT 1
                    """,
                arguments: [termText, translation]
            )
            return row != nil
        }
    }

    func fetchLearningProgress(termId: UUID) throws -> LearningProgress? {
        try pool.read { db in
            let row = try LearningProgressRow.fetchOne(db, key: termId.uuidString)
            return row?.toLearningProgress()
        }
    }

    func updateLearningProgress(termId: UUID, progress: LearningProgress) throws {
        try pool.write { db in
            let row = LearningProgressRow(termId: termId, progress: progress)
            try row.save(db)
        }
    }
}
