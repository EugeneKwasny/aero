//
//  HTTPClient.swift
//  aero
//
//  Executes API requests using URLSession and async/await.
//

import Foundation

struct HTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Sends the request and returns a structured response.
    /// - Parameter variables: environment variables substituted into the request.
    /// - Throws: `HTTPClientError` on invalid input or transport failure.
    func send(_ request: APIRequest, variables: [String: String] = [:]) async throws -> APIResponse {
        let urlRequest = try RequestBuilder.makeURLRequest(from: request) {
            VariableResolver.resolve($0, with: variables)
        }

        let start = Date()
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw HTTPClientError.transport(error)
        }
        let duration = Date().timeIntervalSince(start)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.nonHTTPResponse
        }

        let headers = Dictionary(
            uniqueKeysWithValues: httpResponse.allHeaderFields.compactMap { key, value -> (String, String)? in
                guard let key = key as? String else { return nil }
                return (key, String(describing: value))
            }
        )

        return APIResponse(
            statusCode: httpResponse.statusCode,
            headers: headers,
            data: data,
            duration: duration
        )
    }
}
