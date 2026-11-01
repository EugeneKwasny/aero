//
//  OAuth2Config.swift
//  aero
//
//  OAuth 2.0 configuration stored inline on a request.
//

import Foundation

struct OAuth2Config: Codable, Hashable {
    var grantType: OAuth2GrantType
    var authURL: String
    var tokenURL: String
    var clientID: String
    var clientSecret: String
    var scope: String
    var redirectURI: String
    /// The access token obtained from the last successful token request.
    var accessToken: String

    init(
        grantType: OAuth2GrantType = .clientCredentials,
        authURL: String = "",
        tokenURL: String = "",
        clientID: String = "",
        clientSecret: String = "",
        scope: String = "",
        redirectURI: String = "",
        accessToken: String = ""
    ) {
        self.grantType = grantType
        self.authURL = authURL
        self.tokenURL = tokenURL
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.scope = scope
        self.redirectURI = redirectURI
        self.accessToken = accessToken
    }
}
