//
//  WorkspaceModel.swift
//  aero
//
//  Tracks the open request tabs and the active tab. Each tab owns its
//  own ResponseStore so responses are independent per tab.
//

import SwiftUI

@MainActor
@Observable
final class RequestTab: Identifiable {
    let id: UUID
    let store = ResponseStore()

    init(id: UUID) {
        self.id = id
    }
}

@MainActor
@Observable
final class WorkspaceModel {
    var tabs: [RequestTab] = []
    var activeTabID: UUID?

    var activeTab: RequestTab? {
        tabs.first { $0.id == activeTabID }
    }

    /// Opens the request in a tab (focusing an existing one) and activates it.
    func open(_ id: UUID) {
        if !tabs.contains(where: { $0.id == id }) {
            tabs.append(RequestTab(id: id))
        }
        activeTabID = id
    }

    /// Closes the tab, activating a neighbouring tab if needed.
    func close(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)
        if activeTabID == id {
            activeTabID = tabs.indices.contains(index) ? tabs[index].id : tabs.last?.id
        }
    }

    /// Removes tabs whose request no longer exists (e.g. after deletion).
    func prune(validIDs: Set<UUID>) {
        tabs.removeAll { !validIDs.contains($0.id) }
        if let active = activeTabID, !validIDs.contains(active) {
            activeTabID = tabs.last?.id
        }
    }

    /// Applies environment variables to every open tab's store.
    func applyVariables(_ variables: [String: String]) {
        for tab in tabs {
            tab.store.activeVariables = variables
        }
    }
}
