//
//  SchemaVersions.swift
//  aero
//
//  Versioned schema definitions and the migration plan used by the
//  ModelContainer. Each schema change should add a new VersionedSchema
//  and a migration stage so existing user data is preserved.
//
//  How to evolve the schema:
//    1. Add `enum SchemaV2: VersionedSchema` listing the models at that
//       point, bumping `versionIdentifier`.
//    2. Add a stage to `AeroMigrationPlan.stages`:
//         .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
//       Use `.lightweight` for additive changes (new models/properties with
//       defaults); use `.custom` when data must be transformed.
//    3. Point `currentSchema` at the newest version.
//

import SwiftData

/// Baseline schema (the first versioned snapshot).
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            RequestCollection.self,
            APIRequest.self,
            APIEnvironment.self,
            RequestHistoryEntry.self,
        ]
    }
}

/// The schema version the app currently runs against.
typealias CurrentSchema = SchemaV1

/// Migration plan describing how to move between schema versions.
enum AeroMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        [] // Add stages here as new schema versions are introduced.
    }
}
