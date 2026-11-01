//
//  ContentView.swift
//  aero
//
//  Root three-column layout: collections sidebar, tabbed request
//  editor, and response viewer.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \RequestCollection.createdAt) private var collections: [RequestCollection]
    @Query(sort: \APIEnvironment.createdAt) private var environments: [APIEnvironment]

    @State private var workspace = WorkspaceModel()
    @State private var fallbackStore = ResponseStore()
    @State private var showEnvironmentManager = false
    @AppStorage("activeEnvironmentID") private var activeEnvironmentID: String = ""

    /// Lookup of every request by id across all collections.
    private var allRequests: [UUID: APIRequest] {
        var map: [UUID: APIRequest] = [:]
        for collection in collections {
            for request in collection.requests { map[request.id] = request }
        }
        return map
    }

    private var activeRequest: APIRequest? {
        guard let id = workspace.activeTabID else { return nil }
        return allRequests[id]
    }

    private var activeStore: ResponseStore {
        workspace.activeTab?.store ?? fallbackStore
    }

    private var activeEnvironment: APIEnvironment? {
        environments.first { $0.id.uuidString == activeEnvironmentID }
    }

    /// Two-way binding so the sidebar selection follows the active tab.
    private var sidebarSelection: Binding<UUID?> {
        Binding(
            get: { workspace.activeTabID },
            set: { newValue in
                if let id = newValue {
                    workspace.open(id)
                    syncActiveVariables()
                }
            }
        )
    }

    var body: some View {
        NavigationSplitView {
            CollectionSidebarView(
                collections: collections,
                selectedRequestID: sidebarSelection
            )
        } content: {
            VStack(spacing: 0) {
                if !workspace.tabs.isEmpty {
                    RequestTabBar(workspace: workspace) { allRequests[$0] }
                    Divider()
                }

                if let request = activeRequest {
                    RequestEditorView(request: request)
                } else {
                    ContentUnavailableView {
                        Label("No Request Open", systemImage: "paperplane")
                    } description: {
                        Text("Select a request, or create one in a collection.")
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 360, ideal: 460)
        } detail: {
            ResponseView()
        }
        .navigationTitle("Aero")
        .environment(activeStore)
        .toolbar {
            ToolbarItem {
                environmentMenu
            }
        }
        .sheet(isPresented: $showEnvironmentManager, onDismiss: syncActiveVariables) {
            EnvironmentManagerView()
        }
        .onChange(of: activeEnvironmentID) { _, _ in syncActiveVariables() }
        .onChange(of: Set(allRequests.keys)) { _, newValue in
            workspace.prune(validIDs: newValue)
        }
        .onAppear(perform: syncActiveVariables)
    }

    private var environmentMenu: some View {
        Menu {
            Picker("Environment", selection: $activeEnvironmentID) {
                Text("No Environment").tag("")
                ForEach(environments) { environment in
                    Text(environment.name).tag(environment.id.uuidString)
                }
            }
            Divider()
            Button("Manage Environments…") { showEnvironmentManager = true }
        } label: {
            Label(activeEnvironment?.name ?? "No Environment", systemImage: "globe")
        }
    }

    /// Refreshes variables applied by every open tab on the next send.
    private func syncActiveVariables() {
        let variables = activeEnvironment?.variableMap ?? [:]
        workspace.applyVariables(variables)
        fallbackStore.activeVariables = variables
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RequestCollection.self, APIRequest.self, APIEnvironment.self], inMemory: true)
}
