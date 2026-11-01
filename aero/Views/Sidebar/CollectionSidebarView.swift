//
//  CollectionSidebarView.swift
//  aero
//
//  Leading column: collections and their requests, with CRUD.
//

import SwiftUI
import SwiftData

struct CollectionSidebarView: View {
    @Environment(\.modelContext) private var modelContext

    let collections: [RequestCollection]
    @Binding var selectedRequestID: UUID?

    // Rename state
    @State private var renamingCollection: RequestCollection?
    @State private var renamingRequest: APIRequest?
    @State private var nameField: String = ""

    var body: some View {
        List(selection: $selectedRequestID) {
            ForEach(collections) { collection in
                Section {
                    ForEach(collection.requests.sorted(by: { $0.createdAt < $1.createdAt })) { request in
                        requestRow(request)
                            .tag(request.id)
                    }
                } header: {
                    collectionHeader(collection)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        .overlay {
            if collections.isEmpty {
                ContentUnavailableView {
                    Label("No Collections", systemImage: "tray")
                } description: {
                    Text("Create a collection to start adding requests.")
                } actions: {
                    Button("New Collection", action: addCollection)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: addCollection) {
                    Label("New Collection", systemImage: "folder.badge.plus")
                }
            }
        }
        .alert("Rename Collection", isPresented: renameCollectionBinding) {
            TextField("Name", text: $nameField)
            Button("Cancel", role: .cancel) {}
            Button("Save") { commitCollectionRename() }
        }
        .alert("Rename Request", isPresented: renameRequestBinding) {
            TextField("Name", text: $nameField)
            Button("Cancel", role: .cancel) {}
            Button("Save") { commitRequestRename() }
        }
    }

    // MARK: - Rows

    private func requestRow(_ request: APIRequest) -> some View {
        HStack(spacing: 8) {
            MethodBadge(method: request.method)
            Text(request.name)
                .lineLimit(1)
        }
        .contextMenu {
            Button("Rename") { beginRename(request) }
            Button("Delete", role: .destructive) { delete(request) }
        }
    }

    private func collectionHeader(_ collection: RequestCollection) -> some View {
        HStack {
            Text(collection.name)
            Spacer()
            Menu {
                Button("Add Request") { addRequest(to: collection) }
                Button("Rename") { beginRename(collection) }
                Divider()
                Button("Delete Collection", role: .destructive) { delete(collection) }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    // MARK: - CRUD

    private func addCollection() {
        let collection = RequestCollection(name: "New Collection")
        modelContext.insert(collection)
    }

    private func addRequest(to collection: RequestCollection) {
        let request = APIRequest(name: "New Request")
        request.collection = collection
        modelContext.insert(request)
        selectedRequestID = request.id
    }

    private func delete(_ request: APIRequest) {
        if selectedRequestID == request.id { selectedRequestID = nil }
        modelContext.delete(request)
    }

    private func delete(_ collection: RequestCollection) {
        if let id = selectedRequestID, collection.requests.contains(where: { $0.id == id }) {
            selectedRequestID = nil
        }
        modelContext.delete(collection)
    }

    // MARK: - Rename helpers

    private func beginRename(_ collection: RequestCollection) {
        nameField = collection.name
        renamingCollection = collection
    }

    private func beginRename(_ request: APIRequest) {
        nameField = request.name
        renamingRequest = request
    }

    private func commitCollectionRename() {
        let trimmed = nameField.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { renamingCollection?.name = trimmed }
        renamingCollection = nil
    }

    private func commitRequestRename() {
        let trimmed = nameField.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { renamingRequest?.name = trimmed }
        renamingRequest = nil
    }

    private var renameCollectionBinding: Binding<Bool> {
        Binding(get: { renamingCollection != nil }, set: { if !$0 { renamingCollection = nil } })
    }

    private var renameRequestBinding: Binding<Bool> {
        Binding(get: { renamingRequest != nil }, set: { if !$0 { renamingRequest = nil } })
    }
}
