//
//  RequestTabBar.swift
//  aero
//
//  Horizontal bar of open request tabs above the editor.
//

import SwiftUI

struct RequestTabBar: View {
    let workspace: WorkspaceModel
    /// Resolves a request by id for its name and method.
    let request: (UUID) -> APIRequest?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(workspace.tabs) { tab in
                    tabChip(tab)
                    Divider().frame(height: 18)
                }
            }
        }
        .frame(height: 34)
    }

    private func tabChip(_ tab: RequestTab) -> some View {
        let resolved = request(tab.id)
        let isActive = tab.id == workspace.activeTabID
        return HStack(spacing: 6) {
            if let method = resolved?.method {
                Text(method.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(method.color)
            }
            Text(resolved?.name ?? "Untitled")
                .lineLimit(1)
                .font(.callout)
            Button {
                workspace.close(tab.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(isActive ? Color.secondary.opacity(0.18) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { workspace.activeTabID = tab.id }
    }
}
