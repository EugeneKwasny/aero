//
//  AuthEditorView.swift
//  aero
//
//  Editor for the request's authentication
//  (No Auth / Bearer / Basic / OAuth 2.0).
//

import SwiftUI

struct AuthEditorView: View {
    @Bindable var request: APIRequest

    @State private var oauthService = OAuth2Service()
    @State private var isFetchingToken = false
    @State private var oauthError: String?

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
                case .oauth2:
                    oauth2Fields
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private var oauth2Fields: some View {
        Picker("Grant Type", selection: $request.oauth2.grantType) {
            ForEach(OAuth2GrantType.allCases) { grant in
                Text(grant.displayName).tag(grant)
            }
        }

        if request.oauth2.grantType == .authorizationCode {
            TextField("Authorization URL", text: $request.oauth2.authURL)
                .textFieldStyle(.roundedBorder)
        }
        TextField("Access Token URL", text: $request.oauth2.tokenURL)
            .textFieldStyle(.roundedBorder)
        TextField("Client ID", text: $request.oauth2.clientID)
            .textFieldStyle(.roundedBorder)
        SecureField("Client Secret", text: $request.oauth2.clientSecret)
            .textFieldStyle(.roundedBorder)
        TextField("Scope", text: $request.oauth2.scope)
            .textFieldStyle(.roundedBorder)
        if request.oauth2.grantType == .authorizationCode {
            TextField("Redirect URI", text: $request.oauth2.redirectURI)
                .textFieldStyle(.roundedBorder)
        }

        Section("Token") {
            if !request.oauth2.accessToken.isEmpty {
                Label("Token acquired", systemImage: "checkmark.seal")
                    .foregroundStyle(.green)
                Text(request.oauth2.accessToken)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
            if let oauthError {
                Label(oauthError, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            HStack {
                Button(action: fetchToken) {
                    if isFetchingToken {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Get New Access Token")
                    }
                }
                .disabled(isFetchingToken || request.oauth2.tokenURL.isEmpty)

                if !request.oauth2.accessToken.isEmpty {
                    Button("Clear") { request.oauth2.accessToken = "" }
                }
            }
        }
    }

    private func fetchToken() {
        isFetchingToken = true
        oauthError = nil
        Task {
            defer { isFetchingToken = false }
            do {
                request.oauth2.accessToken = try await oauthService.fetchToken(request.oauth2)
            } catch {
                oauthError = error.localizedDescription
            }
        }
    }
}
