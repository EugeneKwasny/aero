//
//  aeroApp.swift
//  aero
//
//  Created by Eugene Kwasny on 31.10.2026.
//

import SwiftUI
import SwiftData

@main
struct aeroApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: CurrentSchema.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: AeroMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            // Last-resort safety net: if the store still fails to load (e.g. a
            // schema change without a migration stage during development),
            // reset it and try once more rather than crashing on launch.
            removeStore(at: modelConfiguration.url)
            do {
                return try ModelContainer(
                    for: schema,
                    migrationPlan: AeroMigrationPlan.self,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    /// Removes the SQLite store and its sidecar files.
    private static func removeStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let path = url.deletingPathExtension().appendingPathExtension("store\(suffix)")
            try? fileManager.removeItem(at: path)
            // Also try the raw url + suffix in case the extension differs.
            let raw = URL(fileURLWithPath: url.path + suffix)
            try? fileManager.removeItem(at: raw)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
