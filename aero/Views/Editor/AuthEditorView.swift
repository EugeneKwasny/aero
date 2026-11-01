//
//  AuthEditorView.swift
//  aero
//
//  Editor for the request's authentication (No Auth / Bearer / Basic).
//

import SwiftUI

struct AuthEditorView: View {
    @Bindable var request: APIRequest

    var body: some View {
        VStack(spacing: 0) {
            Picker("Auth Type", selection: $request.authType) {
                ForEach(AuthType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(8)

            Divider()

            Form {
                switch request.authType {
                case .none:
                    Text("This request is sent without authentication.")
                        .foregroundStyle(.secondary)
                case .bearer:
                    TextField("Token", text: $request.authToken)
                        .textFieldStyle(.roundedBorder)
                case .basic:
                    TextField("Username", text: $request.authUsername)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $request.authPassword)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}
