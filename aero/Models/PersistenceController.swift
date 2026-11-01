//
//  PersistenceController.swift
//  aero
//
//  Builds the SwiftData ModelContainer. If the on-disk store cannot be
//  opened (e.g. an unsupported schema), the app falls back to an
//  in-memory store instead of crashing or silently deleting data, and
//  signals the UI so it can offer a safe reset.
//

import Foundation
import SwiftData

struct PersistenceController {
    let container: ModelContainer
    /// True when the persistent store failed to load and an in-memory
    /// container is being used instead.
    let loadFailed: Bool

    static func make() -> PersistenceController {
        let schema = Schema(versionedSchema: CurrentSchema.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AeroMigrationPlan.self,
                configurations: [configuration]
            )
            return PersistenceController(container: container, loadFailed: false)
        } catch {
            // Preserve the user's data: run in-memory this session and let the
            // UI offer to reset (which backs up, never deletes).
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            if let fallback = try? ModelContainer(for: schema, configurations: [memory]) {
                return PersistenceController(container: fallback, loadFailed: true)
            }
            fatalError("Could not create an in-memory ModelContainer: \(error)")
        }
    }

    /// Location of the persistent store on disk.
    static var storeURL: URL {
        let schema = Schema(versionedSchema: CurrentSchema.self)
        return ModelConfiguration(schema: schema, isStoredInMemoryOnly: false).url
    }

    /// Moves the current store aside as a timestamped backup so the next
    /// launch starts fresh without destroying the user's data.
    static func backupStore() {
        let fileManager = FileManager.default
        let base = storeURL.path
        let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: base + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            let destination = URL(fileURLWithPath: base + suffix + ".backup-\(stamp)")
            try? fileManager.moveItem(at: source, to: destination)
        }
    }
}
