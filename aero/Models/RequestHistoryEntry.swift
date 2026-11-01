//
//  RequestHistoryEntry.swift
//  aero
//
//  Persistent snapshot of an executed request and its result, used to
//  review and re-run past requests.
//

import Foundation
import SwiftData

@Model
final class RequestHistoryEntry {
    var id: UUID
    var createdAt: Date

    // Request snapshot
    var name: String
    var method: HTTPMethod
    var url: String
    var queryParams: [KeyValueItem]
    var headers: [KeyValueItem]
    var bodyType: BodyType
    var bodyContent: String
    var formFields: [KeyValueItem]
    var multipartParts: [MultipartPart] = []
    var authType: AuthType
    var authToken: String
    var authUsername: String
    var authPassword: String
    var oauth2: OAuth2Config = OAuth2Config()

    // Result summary
    var statusCode: Int?
    var durationMs: Int?
    var responseSize: Int?
    var errorText: String?

    init(request: APIRequest, response: APIResponse?, errorText: String?) {
        self.id = UUID()
        self.createdAt = .now
        self.name = request.name
        self.method = request.method
        self.url = request.url
        self.queryParams = request.queryParams
        self.headers = request.headers
        self.bodyType = request.bodyType
        self.bodyContent = request.bodyContent
        self.formFields = request.formFields
        self.multipartParts = request.multipartParts
        self.authType = request.authType
        self.authToken = request.authToken
        self.authUsername = request.authUsername
        self.authPassword = request.authPassword
        self.oauth2 = request.oauth2
        self.statusCode = response?.statusCode
        self.durationMs = response.map { Int($0.duration * 1000) }
        self.responseSize = response?.size
        self.errorText = errorText
    }

    /// Builds a transient (non-inserted) request from this snapshot.
    func makeRequest() -> APIRequest {
        APIRequest(
            name: name,
            method: method,
            url: url,
            queryParams: queryParams,
            headers: headers,
            bodyType: bodyType,
            bodyContent: bodyContent,
            formFields: formFields,
            multipartParts: multipartParts,
            authType: authType,
            authToken: authToken,
            authUsername: authUsername,
            authPassword: authPassword,
            oauth2: oauth2
        )
    }
}
