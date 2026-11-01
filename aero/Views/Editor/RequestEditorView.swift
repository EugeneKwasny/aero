//
//  RequestEditorView.swift
//  aero
//
//  Middle column: edits and sends a single request.
//

import SwiftUI

struct RequestEditorView: View {
    @Bindable var request: APIRequest
    @Environment(ResponseStore.self) private var store

    @State private var selectedTab: EditorTab = .params

    private enum EditorTab: String, CaseIterable, Identifiable {
        case params = "Params"
        case headers = "Headers"
        case body = "Body"
        case auth = "Auth"
        var id: String { rawValue }
    }

    private var canSend: Bool {
        !request.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !store.isLoading
    }

    var body: some View {
        VStack(spacing: 0) {
            addressBar
            Divider()
            tabBar
            Divider()
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(request.name)
    }

    // MARK: - Address bar

    private var addressBar: some View {
        HStack(spacing: 8) {
            methodMenu
            TextField("https://api.example.com/endpoint", text: $request.url)
                .textFieldStyle(.roundedBorder)
                .onSubmit { send() }

            Button(action: send) {
                if store.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Send")
                }
            }
            .buttonStyle(.glassProminent)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!canSend)
        }
        .padding(8)
    }

    private var methodMenu: some View {
        Menu {
            ForEach(HTTPMethod.allCases) { method in
                Button(method.rawValue) { request.method = method }
            }
        } label: {
            Text(request.method.rawValue)
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(request.method.color)
                .frame(minWidth: 70)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - Tabs

    private var tabBar: some View {
        Picker("", selection: $selectedTab) {
            ForEach(EditorTab.allCases) { tab in
                Text(tabLabel(tab)).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(8)
    }

    private func tabLabel(_ tab: EditorTab) -> String {
        switch tab {
        case .params:
            let n = request.queryParams.filter { $0.isEnabled && !$0.key.isEmpty }.count
            return n > 0 ? "Params (\(n))" : "Params"
        case .headers:
            let n = request.headers.filter { $0.isEnabled && !$0.key.isEmpty }.count
            return n > 0 ? "Headers (\(n))" : "Headers"
        case .body:
            return request.bodyType == .none ? "Body" : "Body •"
        case .auth:
            return request.authType == .none ? "Auth" : "Auth •"
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .params:
            KeyValueEditor(items: $request.queryParams)
        case .headers:
            KeyValueEditor(items: $request.headers, keyPlaceholder: "Header", valuePlaceholder: "Value")
        case .body:
            BodyEditorView(request: request)
        case .auth:
            AuthEditorView(request: request)
        }
    }

    // MARK: - Actions

    private func send() {
        guard canSend else { return }
        Task { await store.run(request) }
    }
}
