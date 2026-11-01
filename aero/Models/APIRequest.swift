//
//  APIRequest.swift
//  aero
//
//  Persistent model describing a single API request.
//

import Foundation
import SwiftData

@Model
final class APIRequest {
    var id: UUID
    var name: String
    var method: HTTPMethod
    var url: String

    /// Query parameters appended to the URL.
    var queryParams: [KeyValueItem]
    /// Request headers.
    var headers: [KeyValueItem]

    var bodyType: BodyType
    /// Raw body text used for JSON and Raw body types.
    var bodyContent: String
    /// Fields used when bodyType is .formURLEncoded.
    var formFields: [KeyValueItem]
    /// Parts used when bodyType is .multipart.
    var multipartParts: [MultipartPart] = []

    var authType: AuthType
    var authToken: String
    var authUsername: String
    var authPassword: String
    var oauth2: OAuth2Config = OAuth2Config()

    var createdAt: Date

    /// Owning collection (inverse of RequestCollection.requests).
    var collection: RequestCollection?

    init(
        id: UUID = UUID(),
        name: String = "New Request",
        method: HTTPMethod = .get,
        url: String = "",
        queryParams: [KeyValueItem] = [],
        headers: [KeyValueItem] = [],
        bodyType: BodyType = .none,
        bodyContent: String = "",
        formFields: [KeyValueItem] = [],
        multipartParts: [MultipartPart] = [],
        authType: AuthType = .none,
        authToken: String = "",
        authUsername: String = "",
        authPassword: String = "",
        oauth2: OAuth2Config = OAuth2Config(),
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.method = method
        self.url = url
        self.queryParams = queryParams
        self.headers = headers
        self.bodyType = bodyType
        self.bodyContent = bodyContent
        self.formFields = formFields
        self.multipartParts = multipartParts
        self.authType = authType
        self.authToken = authToken
        self.authUsername = authUsername
        self.authPassword = authPassword
        self.oauth2 = oauth2
        self.createdAt = createdAt
    }
}
