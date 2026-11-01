//
//  aeroApp.swift
//  aero
//
//  Created by Eugene Kwasny on 31.10.2026.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct aeroApp: App {
    private let persistence = PersistenceController.make()

    var body: some Scene {
        WindowGroup {
            RootView(loadFailed: persistence.loadFailed)
        }
        .modelContainer(persistence.container)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Collection") {
                    persistence.container.mainContext.insert(RequestCollection())
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}

/// Hosts the main UI and surfaces a data-load failure as a non-destructive
/// alert rather than crashing or wiping the store.
private struct RootView: View {
    let loadFailed: Bool
    @State private var showLoadAlert: Bool

    init(loadFailed: Bool) {
        self.loadFailed = loadFailed
        _showLoadAlert = State(initialValue: loadFailed)
    }

    var body: some View {
        ContentView()
            .alert("Couldn’t Open Saved Data", isPresented: $showLoadAlert) {
                Button("Continue Without Saving", role: .cancel) {}
                Button("Reset & Quit", role: .destructive) {
                    PersistenceController.backupStore()
                    NSApplication.shared.terminate(nil)
                }
            } message: {
                Text("""
                Aero is running with temporary storage, so your existing data is left untouched. \
                Choose “Reset & Quit” to move the old data aside (a backup is kept) and start \
                fresh on the next launch.
                """)
            }
    }
}
