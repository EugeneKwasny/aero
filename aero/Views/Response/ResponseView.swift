//
//  ResponseView.swift
//  aero
//
//  Trailing column: shows the result of the last executed request with
//  Preview / Raw / Headers tabs, JSON pretty-printing, and body search.
//

import SwiftUI
import AppKit

struct ResponseView: View {
    @Environment(ResponseStore.self) private var store

    @State private var tab: ResponseTab = .preview
    @State private var searchText = ""

    private enum ResponseTab: String, CaseIterable, Identifiable {
        case preview = "Preview"
        case raw = "Raw"
        case headers = "Headers"
        var id: String { rawValue }
    }

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView("Sending…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = store.errorMessage {
                ContentUnavailableView {
                    Label("Request Failed", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                }
            } else if let response = store.response {
                content(for: response)
            } else {
                ContentUnavailableView {
                    Label("No Response", systemImage: "arrow.down.circle")
                } description: {
                    Text("Send a request to see the response here.")
                }
            }
        }
    }

    // MARK: - Content

    private func content(for response: APIResponse) -> some View {
        VStack(spacing: 0) {
            statusBar(response)
            Divider()

            Picker("", selection: $tab) {
                ForEach(ResponseTab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(8)

            if tab != .headers {
                toolbar(for: response)
            }

            Divider()

            switch tab {
            case .preview:
                bodyScroll(prettyBody(response))
            case .raw:
                bodyScroll(response.bodyString ?? "(binary data, \(response.size) bytes)")
            case .headers:
                headersList(response)
            }
        }
    }

    private func statusBar(_ response: APIResponse) -> some View {
        HStack(spacing: 12) {
            Text("\(response.statusCode)")
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(statusColor(response.statusCode))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .glassEffect(.regular.tint(statusColor(response.statusCode).opacity(0.25)), in: .capsule)
            Text(response.statusText)
                .foregroundStyle(.secondary)
            Spacer()
            Label("\(Int(response.duration * 1000)) ms", systemImage: "clock")
            Label(byteCount(response.size), systemImage: "doc")
        }
        .font(.callout)
        .padding(8)
    }

    private func toolbar(for response: APIResponse) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Find in body", text: $searchText)
                .textFieldStyle(.roundedBorder)
            if !searchText.isEmpty {
                Text("\(matchCount(in: displayedText(response)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button {
                copyToPasteboard(displayedText(response))
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Copy body")
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func bodyScroll(_ text: String) -> some View {
        ScrollView {
            Text(highlighted(text))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
        }
    }

    private func headersList(_ response: APIResponse) -> some View {
        List {
            ForEach(response.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                VStack(alignment: .leading, spacing: 2) {
                    Text(key).font(.callout.weight(.semibold))
                    Text(value)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Helpers

    /// Pretty-prints JSON bodies when possible, otherwise returns raw text.
    private func prettyBody(_ response: APIResponse) -> String {
        if let pretty = JSONFormatter.prettyPrinted(response.data) {
            return pretty
        }
        return response.bodyString ?? "(binary data, \(response.size) bytes)"
    }

    private func displayedText(_ response: APIResponse) -> String {
        switch tab {
        case .preview: return prettyBody(response)
        case .raw: return response.bodyString ?? ""
        case .headers: return ""
        }
    }

    /// Builds an AttributedString with case-insensitive highlights for the
    /// current search term. Skipped for very large bodies to stay responsive.
    private func highlighted(_ text: String) -> AttributedString {
        guard !searchText.isEmpty, text.count < 200_000 else {
            return AttributedString(text)
        }
        var result = AttributedString()
        var searchStart = text.startIndex
        while let range = text.range(of: searchText, options: .caseInsensitive, range: searchStart..<text.endIndex) {
            result += AttributedString(String(text[searchStart..<range.lowerBound]))
            var match = AttributedString(String(text[range]))
            match.backgroundColor = .yellow
            match.foregroundColor = .black
            result += match
            if range.isEmpty { searchStart = text.endIndex; break }
            searchStart = range.upperBound
        }
        result += AttributedString(String(text[searchStart...]))
        return result
    }

    private func matchCount(in text: String) -> Int {
        guard !searchText.isEmpty else { return 0 }
        var count = 0
        var searchStart = text.startIndex
        while let range = text.range(of: searchText, options: .caseInsensitive, range: searchStart..<text.endIndex) {
            count += 1
            if range.isEmpty { break }
            searchStart = range.upperBound
        }
        return count
    }

    private func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        default: return .red
        }
    }

    private func byteCount(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
