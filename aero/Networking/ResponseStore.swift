//
//  ResponseStore.swift
//  aero
//
//  Observable state shared between the request editor and the
//  response viewer. Holds the in-flight / last response for the UI.
//

import SwiftUI

@MainActor
@Observable
final class ResponseStore {
    var isLoading = false
    var response: APIResponse?
    var errorMessage: String?

    /// Variables from the active environment, applied on the next send.
    var activeVariables: [String: String] = [:]

    private let client: HTTPClient

    init(client: HTTPClient = HTTPClient()) {
        self.client = client
    }

    /// Executes the request and publishes the result.
    func run(_ request: APIRequest) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            response = try await client.send(request, variables: activeVariables)
        } catch {
            response = nil
            errorMessage = error.localizedDescription
        }
    }

    /// Clears any previous result, e.g. when switching requests.
    func reset() {
        response = nil
        errorMessage = nil
    }
}
