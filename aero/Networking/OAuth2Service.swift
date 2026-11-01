//
//  OAuth2Service.swift
//  aero
//
//  Fetches OAuth 2.0 access tokens via the client-credentials and
//  authorization-code grant types.
//

import Foundation
import AuthenticationServices

enum OAuth2Error: LocalizedError {
    case invalidURL
    case missingRedirectScheme
    case noAuthorizationCode
    case server(status: Int, body: String)
    case noAccessToken

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid OAuth URL."
        case .missingRedirectScheme: return "Redirect URI must include a scheme (e.g. myapp://callback)."
        case .noAuthorizationCode: return "No authorization code returned."
        case .server(let status, let body): return "Token endpoint error (\(status)): \(body)"
        case .noAccessToken: return "Response did not contain an access_token."
        }
    }
}

@MainActor
final class OAuth2Service: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func fetchToken(_ config: OAuth2Config) async throws -> String {
        switch config.grantType {
        case .clientCredentials:
            return try await clientCredentials(config)
        case .authorizationCode:
            return try await authorizationCode(config)
        }
    }

    // MARK: - Client credentials

    private func clientCredentials(_ config: OAuth2Config) async throws -> String {
        var params = ["grant_type": "client_credentials"]
        if !config.scope.isEmpty { params["scope"] = config.scope }
        return try await requestToken(config, extraParams: params)
    }

    // MARK: - Authorization code

    private func authorizationCode(_ config: OAuth2Config) async throws -> String {
        guard var components = URLComponents(string: config.authURL) else {
            throw OAuth2Error.invalidURL
        }
        guard let scheme = URL(string: config.redirectURI)?.scheme else {
            throw OAuth2Error.missingRedirectScheme
        }

        let state = UUID().uuidString
        var items = components.queryItems ?? []
        items.append(contentsOf: [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "state", value: state),
        ])
        if !config.scope.isEmpty {
            items.append(URLQueryItem(name: "scope", value: config.scope))
        }
        components.queryItems = items

        guard let authorizeURL = components.url else { throw OAuth2Error.invalidURL }

        let code = try await authorize(url: authorizeURL, callbackScheme: scheme)

        return try await requestToken(config, extraParams: [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": config.redirectURI,
        ])
    }

    private func authorize(url: URL, callbackScheme: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard
                    let callbackURL,
                    let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    continuation.resume(throwing: OAuth2Error.noAuthorizationCode)
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self
            self.session = session
            session.start()
        }
    }

    // MARK: - Token request

    private func requestToken(_ config: OAuth2Config, extraParams: [String: String]) async throws -> String {
        guard let url = URL(string: config.tokenURL) else { throw OAuth2Error.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var params = extraParams
        // Prefer HTTP Basic client authentication; fall back to body params.
        if !config.clientID.isEmpty {
            let pair = "\(config.clientID):\(config.clientSecret)"
            if let data = pair.data(using: .utf8) {
                request.setValue("Basic \(data.base64EncodedString())", forHTTPHeaderField: "Authorization")
            }
        } else {
            params["client_id"] = config.clientID
            params["client_secret"] = config.clientSecret
        }

        request.httpBody = formEncode(params).data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw OAuth2Error.server(status: status, body: String(data: data, encoding: .utf8) ?? "")
        }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let token = json["access_token"] as? String
        else {
            throw OAuth2Error.noAccessToken
        }
        return token
    }

    private func formEncode(_ params: [String: String]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return params.map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(k)=\(v)"
        }.joined(separator: "&")
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
}
