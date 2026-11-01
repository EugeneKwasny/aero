//
//  BodyEditorView.swift
//  aero
//
//  Editor for the request body (None / JSON / Raw / Form URL-Encoded).
//

import SwiftUI

struct BodyEditorView: View {
    @Bindable var request: APIRequest

    var body: some View {
        VStack(spacing: 0) {
            Picker("Body Type", selection: $request.bodyType) {
                ForEach(BodyType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(8)

            Divider()

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch request.bodyType {
        case .none:
            Text("This request has no body.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .json:
            jsonEditor
        case .raw:
            textEditor
        case .formURLEncoded:
            KeyValueEditor(items: $request.formFields, keyPlaceholder: "Field", valuePlaceholder: "Value")
        }
    }

    // MARK: - JSON

    private var jsonEditor: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                validityLabel
                Spacer()
                Button("Format") {
                    if let pretty = JSONFormatter.prettyPrinted(request.bodyContent) {
                        request.bodyContent = pretty
                    }
                }
                .disabled(request.bodyContent.isEmpty || !JSONFormatter.isValid(request.bodyContent))
            }
            .padding(8)
            Divider()
            textEditor
        }
    }

    @ViewBuilder
    private var validityLabel: some View {
        if request.bodyContent.isEmpty {
            EmptyView()
        } else if JSONFormatter.isValid(request.bodyContent) {
            Label("Valid JSON", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
                .font(.caption)
        } else {
            Label("Invalid JSON", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
                .font(.caption)
        }
    }

    // MARK: - Shared text editor

    private var textEditor: some View {
        TextEditor(text: $request.bodyContent)
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(4)
    }
}
