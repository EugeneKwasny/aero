//
//  EnvironmentManagerView.swift
//  aero
//
//  Sheet for managing environments and their variables.
//

import SwiftUI
import SwiftData

struct EnvironmentManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \APIEnvironment.createdAt) private var environments: [APIEnvironment]

    @State private var selectedID: UUID?

    private var selectedEnvironment: APIEnvironment? {
        environments.first { $0.id == selectedID }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedID) {
                ForEach(environments) { environment in
                    Text(environment.name).tag(environment.id)
                }
                .onDelete(perform: deleteEnvironments)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addEnvironment) {
                        Label("New Environment", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let environment = selectedEnvironment {
                EnvironmentDetailView(environment: environment)
            } else {
                ContentUnavailableView {
                    Label("No Environment Selected", systemImage: "globe")
                } description: {
                    Text("Select or create an environment to edit its variables.")
                }
            }
        }
        .frame(minWidth: 640, minHeight: 420)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func addEnvironment() {
        let environment = APIEnvironment(name: "New Environment")
        modelContext.insert(environment)
        selectedID = environment.id
    }

    private func deleteEnvironments(_ offsets: IndexSet) {
        for index in offsets {
            let environment = environments[index]
            if selectedID == environment.id { selectedID = nil }
            modelContext.delete(environment)
        }
    }
}

/// Edits a single environment's name and variables.
private struct EnvironmentDetailView: View {
    @Bindable var environment: APIEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                TextField("Name", text: $environment.name)
            }
            .formStyle(.grouped)
            .frame(height: 70)

            Divider()

            Text("Variables")
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.top, 8)

            KeyValueEditor(
                items: $environment.variables,
                keyPlaceholder: "Variable",
                valuePlaceholder: "Value"
            )
        }
    }
}
