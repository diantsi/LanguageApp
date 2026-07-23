//
//  DatabaseSchema.swift
//  JohnsonApp
//

import Foundation
import GRDB


enum DatabaseSchema {

    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif


        migrator.registerMigration("v1_initial") { db in
            try db.create(table: "terms") { t in
                t.column("id", .text).primaryKey()
                t.column("termText", .text).notNull()
                t.column("translation", .text).notNull()
                t.column("hint", .text)
                t.column("termLanguage", .text).notNull()
                t.column("translationLanguage", .text).notNull()
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
            }

            try db.create(
                index: "idx_terms_text_translation",
                on: "terms",
                columns: ["termText", "translation"]
            )

            try db.create(table: "learning_progress") { t in
                t.column("termId", .text)
                    .primaryKey()
                    .references("terms", column: "id", onDelete: .cascade)
                t.column("stability", .double).notNull().defaults(to: 0.0)
                t.column("difficulty", .double).notNull().defaults(to: 0.0)
                t.column("dueDate", .double).notNull()
                t.column("lastReviewDate", .double)          
                t.column("repetitions", .integer).notNull().defaults(to: 0)
                t.column("lapses", .integer).notNull().defaults(to: 0)
            }

            try db.create(
                index: "idx_lp_due_date",
                on: "learning_progress",
                columns: ["dueDate"]
            )
        }

        return migrator
    }
}

final class AppDatabase: Sendable {


    static func makeConfiguration() -> Configuration {
        var config = Configuration()
        config.prepareDatabase { db in
            let collation = DatabaseCollation("swift_nocase") { (s1, s2) in
                s1.localizedCaseInsensitiveCompare(s2)
            }
            db.add(collation: collation)
        }
        return config
    }


    static let shared: DatabasePool = {
        do {
            let folderURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbURL = folderURL.appendingPathComponent("johnson_app.sqlite")
            let pool = try DatabasePool(path: dbURL.path, configuration: makeConfiguration())
            try DatabaseSchema.migrator.migrate(pool)
            return pool
        } catch {
            fatalError("Could not create DatabasePool: \(error)")
        }
    }()

    static func makeInMemory() throws -> DatabaseQueue {
        let queue = try DatabaseQueue(configuration: makeConfiguration())
        try DatabaseSchema.migrator.migrate(queue)
        return queue
    }

    private init() {}
}
