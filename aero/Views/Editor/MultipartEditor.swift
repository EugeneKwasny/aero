//
//  MultipartEditor.swift
//  aero
//
//  Editor for multipart/form-data parts (text fields and files).
//

import SwiftUI
import AppKit

struct MultipartEditor: View {
    @Binding var parts: [MultipartPart]

    var body: some View {
        VStack(spacing: 0) {
            if parts.isEmpty {
                ContentUnavailableView {
                    Label("No Parts", systemImage: "doc.on.doc")
                } description: {
                    Text("Add a text or file part to build the form.")
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach($parts) { $part in
                        row(for: $part)
                    }
                    .onDelete { parts.remove(atOffsets: $0) }
                }
                .listStyle(.inset)
            }

            Divider()
            HStack {
                Button {
                    parts.append(MultipartPart())
                } label: {
                    Label("Add Part", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding(8)
        }
    }

    private func row(for part: Binding<MultipartPart>) -> some View {
        HStack(spacing: 8) {
            Toggle("", isOn: part.isEnabled)
                .labelsHidden()
                .toggleStyle(.checkbox)

            TextField("Name", text: part.name)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 140)

            Picker("", selection: part.isFile) {
                Text("Text").tag(false)
                Text("File").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()

            if part.wrappedValue.isFile {
                Button {
                    chooseFile(for: part)
                } label: {
                    Text(part.wrappedValue.fileName.isEmpty ? "Choose File…" : part.wrappedValue.fileName)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                TextField("Value", text: part.value)
                    .textFieldStyle(.roundedBorder)
            }

            Button(role: .destructive) {
                parts.removeAll { $0.id == part.wrappedValue.id }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .opacity(part.wrappedValue.isEnabled ? 1 : 0.5)
    }

    private func chooseFile(for part: Binding<MultipartPart>) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let bookmark = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            part.wrappedValue.bookmark = bookmark
            part.wrappedValue.fileName = url.lastPathComponent
        }
    }
}
