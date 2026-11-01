//
//  CurlImportView.swift
//  aero
//
//  Sheet that parses a pasted cURL command into a new request.
//

import SwiftUI

struct CurlImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var showError = false

    let onImport: (APIRequest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import from cURL")
                .font(.headline)
            Text("Paste a cURL command below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 180)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))

            if showError {
                Label("Could not parse a request from this input.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Import") { performImport() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 320)
    }

    private func performImport() {
        if let request = CurlParser.parse(text) {
            onImport(request)
            dismiss()
        } else {
            showError = true
        }
    }
}
