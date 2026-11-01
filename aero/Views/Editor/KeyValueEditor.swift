//
//  KeyValueEditor.swift
//  aero
//
//  Reusable editor for a list of enableable key/value pairs.
//  Used for query parameters, headers, and form fields.
//

import SwiftUI

struct KeyValueEditor: View {
    @Binding var items: [KeyValueItem]
    var keyPlaceholder: String = "Key"
    var valuePlaceholder: String = "Value"

    var body: some View {
        VStack(spacing: 0) {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("Nothing here yet", systemImage: "list.bullet")
                } description: {
                    Text("Add a row to get started.")
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach($items) { $item in
                        row(for: $item)
                    }
                    .onDelete { items.remove(atOffsets: $0) }
                }
                .listStyle(.inset)
            }

            Divider()
            HStack {
                Button {
                    items.append(KeyValueItem())
                } label: {
                    Label("Add Row", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding(8)
        }
    }

    private func row(for item: Binding<KeyValueItem>) -> some View {
        HStack(spacing: 8) {
            Toggle("", isOn: item.isEnabled)
                .labelsHidden()
                .toggleStyle(.checkbox)

            TextField(keyPlaceholder, text: item.key)
                .textFieldStyle(.roundedBorder)

            TextField(valuePlaceholder, text: item.value)
                .textFieldStyle(.roundedBorder)

            Button(role: .destructive) {
                items.removeAll { $0.id == item.wrappedValue.id }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .opacity(item.wrappedValue.isEnabled ? 1 : 0.5)
    }
}
