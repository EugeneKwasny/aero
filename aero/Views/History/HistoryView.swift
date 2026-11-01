//
//  HistoryView.swift
//  aero
//
//  Sheet listing executed requests with the ability to review and
//  re-send them.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RequestHistoryEntry.createdAt, order: .reverse) private var entries: [RequestHistoryEntry]

    @State private var selectedID: UUID?
    @State private var store = ResponseStore()

    private var selectedEntry: RequestHistoryEntry? {
        entries.first { $0.id == selectedID }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedID) {
                ForEach(entries) { entry in
                    historyRow(entry).tag(entry.id)
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 300)
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView {
                        Label("No History", systemImage: "clock")
                    } description: {
                        Text("Sent requests will appear here.")
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Clear All", role: .destructive, action: clearAll)
                        .disabled(entries.isEmpty)
                }
            }
        } detail: {
            if let entry = selectedEntry {
                HistoryDetailView(entry: entry)
            } else {
                ContentUnavailableView {
                    Label("No Entry Selected", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Select an entry to review or re-send it.")
                }
            }
        }
        .frame(minWidth: 820, minHeight: 500)
        .environment(store)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func historyRow(_ entry: RequestHistoryEntry) -> some View {
        HStack(spacing: 8) {
            MethodBadge(method: entry.method)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.url.isEmpty ? "(no url)" : entry.url)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    statusLabel(entry)
                    Text(entry.createdAt, format: .dateTime.month().day().hour().minute())
                        .foregroundStyle(.tertiary)
                }
                .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func statusLabel(_ entry: RequestHistoryEntry) -> some View {
        if let code = entry.statusCode {
            Text("\(code)").foregroundStyle(statusColor(code))
        } else if entry.errorText != nil {
            Text("Error").foregroundStyle(.red)
        } else {
            Text("—").foregroundStyle(.secondary)
        }
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        default: return .red
        }
    }

    private func deleteEntries(_ offsets: IndexSet) {
        for index in offsets {
            let entry = entries[index]
            if selectedID == entry.id { selectedID = nil }
            modelContext.delete(entry)
        }
    }

    private func clearAll() {
        for entry in entries { modelContext.delete(entry) }
        selectedID = nil
    }
}

/// Detail pane: summary of a history entry plus a re-send action.
private struct HistoryDetailView: View {
    let entry: RequestHistoryEntry
    @Environment(ResponseStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                MethodBadge(method: entry.method)
                Text(entry.url)
                    .lineLimit(1)
                    .textSelection(.enabled)
                Spacer()
                Button("Re-send") {
                    Task { await store.run(entry.makeRequest()) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.isLoading)
            }
            .padding(8)
            Divider()
            ResponseView()
        }
    }
}
