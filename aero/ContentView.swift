//
//  ContentView.swift
//  aero
//
//  Root three-column layout: collections sidebar, request editor,
//  and response viewer.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \RequestCollection.createdAt) private var collections: [RequestCollection]
    @State private var selectedRequestID: UUID?
    @State private var responseStore = ResponseStore()

    /// The request currently selected in the sidebar, if any.
    private var selectedRequest: APIRequest? {
        for collection in collections {
            if let match = collection.requests.first(where: { $0.id == selectedRequestID }) {
                return match
            }
        }
        return nil
    }

    var body: some View {
        NavigationSplitView {
            CollectionSidebarView(
                collections: collections,
                selectedRequestID: $selectedRequestID
            )
        } content: {
            if let request = selectedRequest {
                RequestEditorView(request: request)
                    .navigationSplitViewColumnWidth(min: 360, ideal: 460)
            } else {
                ContentUnavailableView {
                    Label("No Request Selected", systemImage: "paperplane")
                } description: {
                    Text("Select a request, or create one in a collection.")
                }
                .navigationSplitViewColumnWidth(min: 360, ideal: 460)
            }
        } detail: {
            ResponseView()
        }
        .navigationTitle("Aero")
        .environment(responseStore)
        .onChange(of: selectedRequestID) { _, _ in
            responseStore.reset()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RequestCollection.self, APIRequest.self], inMemory: true)
}
