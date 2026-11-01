//
//  Enums.swift
//  aero
//
//  Core enumerations describing an API request.
//

import SwiftUI

/// Supported HTTP methods for a request.
enum HTTPMethod: String, Codable, CaseIterable, Identifiable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"

    var id: String { rawValue }

    /// Accent color used to visually distinguish the method in the UI.
    var color: Color {
        switch self {
        case .get: return .green
        case .post: return .blue
        case .put: return .orange
        case .patch: return .purple
        case .delete: return .red
        case .head, .options: return .gray
        }
    }

    /// Whether this method typically carries a request body.
    var allowsBody: Bool {
        switch self {
        case .post, .put, .patch, .delete: return true
        case .get, .head, .options: return false
        }
    }
}

/// The kind of body attached to a request.
enum BodyType: String, Codable, CaseIterable, Identifiable {
    case none
    case json
    case raw
    case formURLEncoded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .json: return "JSON"
        case .raw: return "Raw"
        case .formURLEncoded: return "Form URL-Encoded"
        }
    }
}

/// The authentication strategy applied to a request.
enum AuthType: String, Codable, CaseIterable, Identifiable {
    case none
    case bearer
    case basic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "No Auth"
        case .bearer: return "Bearer Token"
        case .basic: return "Basic Auth"
        }
    }
}
