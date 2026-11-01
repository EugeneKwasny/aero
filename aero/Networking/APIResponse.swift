//
//  APIResponse.swift
//  aero
//
//  Value type holding the result of an executed HTTP request.
//

import Foundation

struct APIResponse {
    let statusCode: Int
    let headers: [String: String]
    let data: Data
    /// Wall-clock time the request took, in seconds.
    let duration: TimeInterval

    /// Number of bytes in the response body.
    var size: Int { data.count }

    /// Localized description of the status code, e.g. "OK".
    var statusText: String {
        HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized
    }

    /// Body decoded as UTF-8 text, if possible.
    var bodyString: String? {
        String(data: data, encoding: .utf8)
    }

    var isSuccess: Bool { (200..<300).contains(statusCode) }
}

/// Errors surfaced to the UI when a request cannot be executed.
enum HTTPClientError: LocalizedError {
    case invalidURL(String)
    case nonHTTPResponse
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url.isEmpty ? "(empty)" : url)"
        case .nonHTTPResponse:
            return "The server returned a non-HTTP response."
        case .transport(let error):
            return error.localizedDescription
        }
    }
}
