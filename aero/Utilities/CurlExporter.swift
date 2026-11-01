//
//  CurlExporter.swift
//  aero
//
//  Builds a cURL command string from an APIRequest. Values are exported
//  literally (including any {{variable}} placeholders).
//

import Foundation

enum CurlExporter {

    static func export(_ request: APIRequest) -> String {
        var parts: [String] = ["curl"]

        if request.method != .get {
            parts.append("-X \(request.method.rawValue)")
        }

        parts.append(quote(urlWithQuery(request)))

        for header in request.headers where header.isEnabled && !header.key.isEmpty {
            parts.append("-H \(quote("\(header.key): \(header.value)"))")
        }

        switch request.authType {
        case .none:
            break
        case .bearer where !request.authToken.isEmpty:
            parts.append("-H \(quote("Authorization: Bearer \(request.authToken)"))")
        case .bearer:
            break
        case .basic:
            parts.append("-u \(quote("\(request.authUsername):\(request.authPassword)"))")
        }

        if let body = bodyString(request) {
            parts.append("--data \(quote(body))")
        }

        return parts.joined(separator: " \\\n  ")
    }

    // MARK: - Helpers

    private static func urlWithQuery(_ request: APIRequest) -> String {
        let enabled = request.queryParams.filter { $0.isEnabled && !$0.key.isEmpty }
        guard !enabled.isEmpty else { return request.url }
        let query = enabled.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        return request.url + (request.url.contains("?") ? "&" : "?") + query
    }

    private static func bodyString(_ request: APIRequest) -> String? {
        switch request.bodyType {
        case .none:
            return nil
        case .json, .raw:
            return request.bodyContent.isEmpty ? nil : request.bodyContent
        case .formURLEncoded:
            let fields = request.formFields.filter { $0.isEnabled && !$0.key.isEmpty }
            guard !fields.isEmpty else { return nil }
            return fields.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        }
    }

    /// Wraps a value in single quotes, escaping embedded single quotes.
    private static func quote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
