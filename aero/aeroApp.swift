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
        let schema = Schema([
            RequestCollection.self,
            APIRequest.self,
            APIEnvironment.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
